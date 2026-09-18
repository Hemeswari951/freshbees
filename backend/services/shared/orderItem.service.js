const pool = require('../../config/db');
const notificationService = require('./notification.service');

class OrderItemError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.statusCode = statusCode;
  }
}

// ── Ownership + row lookup ────────────────────────────────────────────────
// Every action below starts here: load the item, confirm it belongs to the
// calling shop owner's shop, and hand back the row so the caller can check
// its current status. Throws 404/403 — never lets one seller touch (or even
// learn the existence of) another seller's order item.
async function loadOwnedItem(orderItemId, shopId) {
  const { rows } = await pool.query(
    `SELECT order_item_id, order_id, shop_id, product_id, variant_id, quantity, item_status
     FROM order_items
     WHERE order_item_id = $1`,
    [orderItemId]
  );
  const item = rows[0];
  if (!item) {
    throw new OrderItemError('Order item not found', 404);
  }
  if (item.shop_id !== shopId) {
    throw new OrderItemError('You do not have permission to update this item', 403);
  }
  return item;
}

function assertTransition(current, next) {
  if (!notificationService.isValidTransition(current, next)) {
    throw new OrderItemError(
      `Cannot move item from '${current}' to '${next}'`,
      400
    );
  }
}

// ── CONFIRM ORDER — Pending -> Processing ──────────────────────────────────
// Re-checks stock at the moment of confirmation (never trusts what was
// available when the customer placed the order) and decrements it in the
// same statement that flips the status, so two overlapping confirm calls
// can never double-decrement: the second one simply won't find a row still
// sitting at 'Pending' once the first has already moved it on.
async function confirmOrder(orderItemId, shopOwnerId, shopId) {
  const item = await loadOwnedItem(orderItemId, shopId);
  assertTransition(item.item_status, 'Processing');

  if (item.variant_id) {
    const { rows: variantRows } = await pool.query(
      `SELECT stock_quantity FROM product_variants WHERE variant_id = $1`,
      [item.variant_id]
    );
    const available = variantRows[0]?.stock_quantity;
    if (available !== null && available !== undefined && available < item.quantity) {
      throw new OrderItemError('Insufficient stock available.', 400);
    }
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: updatedRows } = await client.query(
      `UPDATE order_items
       SET item_status = 'Processing', updated_at = NOW()
       WHERE order_item_id = $1 AND item_status = 'Pending'
       RETURNING order_item_id, item_status`,
      [orderItemId]
    );

    if (!updatedRows[0]) {
      // Someone else already moved it (e.g. a second tap) — bail out
      // cleanly instead of decrementing stock for nothing.
      throw new OrderItemError(`Cannot move item from '${item.item_status}' to 'Processing'`, 400);
    }

    if (item.variant_id) {
      await client.query(
        `UPDATE product_variants
         SET stock_quantity = GREATEST(stock_quantity - $1, 0), updated_at = NOW()
         WHERE variant_id = $2`,
        [item.quantity, item.variant_id]
      );
    }

    await client.query('COMMIT');
    await notificationService.notifyItemStatusChange(orderItemId, 'Processing');
    return updatedRows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// ── CANCEL ORDER — Pending -> Cancelled ────────────────────────────────────
async function cancelOrder(orderItemId, shopOwnerId, shopId, reason) {
  if (!reason || !reason.trim()) {
    throw new OrderItemError('A cancellation reason is required', 400);
  }

  const item = await loadOwnedItem(orderItemId, shopId);
  assertTransition(item.item_status, 'Cancelled');

  const { rows: updatedRows } = await pool.query(
    `UPDATE order_items
     SET item_status = 'Cancelled',
         cancellation_reason = $2,
         cancelled_at = NOW(),
         cancelled_by = 'shop',
         updated_at = NOW()
     WHERE order_item_id = $1 AND item_status = $3
     RETURNING order_item_id, item_status, cancellation_reason`,
    [orderItemId, reason.trim(), item.item_status]
  );

  if (!updatedRows[0]) {
    throw new OrderItemError(`Cannot move item from '${item.item_status}' to 'Cancelled'`, 400);
  }

  await notificationService.notifyItemStatusChange(orderItemId, 'Cancelled', {
    cancellationReason: reason.trim(),
    cancelledBy: 'shop',
  });
  return updatedRows[0];
}

// ── PACKED / SHIPPED / DELIVERED — simple linear transitions ──────────────
function makeSimpleTransition(newStatus) {
  return async function (orderItemId, shopOwnerId, shopId) {
    const item = await loadOwnedItem(orderItemId, shopId);
    assertTransition(item.item_status, newStatus);

    const { rows: updatedRows } = await pool.query(
      `UPDATE order_items
       SET item_status = $1, updated_at = NOW()
       WHERE order_item_id = $2 AND item_status = $3
       RETURNING order_item_id, item_status`,
      [newStatus, orderItemId, item.item_status]
    );

    if (!updatedRows[0]) {
      throw new OrderItemError(`Cannot move item from '${item.item_status}' to '${newStatus}'`, 400);
    }

    await notificationService.notifyItemStatusChange(orderItemId, newStatus);
    return updatedRows[0];
  };
}

const markPacked = makeSimpleTransition('Packed');
const markShipped = makeSimpleTransition('Shipped');
const markDelivered = makeSimpleTransition('Delivered');

// ── Legacy generic entry point — kept so nothing else that may already
// call updateItemStatus(...) breaks, but every NEW call site should use
// the named functions above instead (each one carries its own rules —
// stock check for confirm, required reason for cancel — that this generic
// version can't enforce for you).
async function updateItemStatus(orderItemId, newStatus, shopOwnerId) {
  const { rows: ownerRows } = await pool.query(
    `SELECT shop_id FROM shop_owners WHERE shop_owner_id = $1`,
    [shopOwnerId]
  );
  const shopId = ownerRows[0]?.shop_id;
  if (!shopId) {
    throw new OrderItemError('Shop owner not found', 404);
  }

  switch (newStatus) {
    case 'Processing':
      return confirmOrder(orderItemId, shopOwnerId, shopId);
    case 'Cancelled':
      throw new OrderItemError('Use cancelOrder(orderItemId, shopOwnerId, shopId, reason) instead', 400);
    case 'Packed':
      return markPacked(orderItemId, shopOwnerId, shopId);
    case 'Shipped':
      return markShipped(orderItemId, shopOwnerId, shopId);
    case 'Delivered':
      return markDelivered(orderItemId, shopOwnerId, shopId);
    default: {
      const item = await loadOwnedItem(orderItemId, shopId);
      assertTransition(item.item_status, newStatus);
      throw new OrderItemError(`Unsupported status '${newStatus}'`, 400);
    }
  }
}

module.exports = {
  OrderItemError,
  confirmOrder,
  cancelOrder,
  markPacked,
  markShipped,
  markDelivered,
  updateItemStatus,
};