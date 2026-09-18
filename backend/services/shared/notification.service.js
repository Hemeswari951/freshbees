const pool = require('../../config/db');
const notificationModel = require('../../models/shared/notification.model');

// ── Order item status lifecycle ─────────────────────────────────────────
// Pending -> Processing -> Packed -> Shipped -> Delivered
// Pending -> Cancelled (the only allowed cancellation — once the shop has
// confirmed/started preparing the order, it can no longer be cancelled
// through this flow; that has to go through support instead).
// Delivered / Cancelled are terminal — no further transitions allowed.
const TRANSITIONS = {
  Pending: ['Processing', 'Cancelled'],
  Processing: ['Packed'],
  Packed: ['Shipped'],
  Shipped: ['Delivered'],
  Delivered: [],
  Cancelled: [],
};

function isValidTransition(currentStatus, newStatus) {
  return (TRANSITIONS[currentStatus] || []).includes(newStatus);
}

// ── Trigger A: New Order placed ─────────────────────────────────────────
// Call this once, right after an order + its order_items are successfully
// inserted (checkout flow). Notifies:
//   - the shop_owner of EACH item (per-item, so each notification is
//     directly actionable — tap it, see that one item, Accept/Hold/Cancel)
//   - EVERY active admin, ONE summary notification per order (not per item)
async function notifyNewOrder(orderId) {
  const { rows: items } = await pool.query(
    `SELECT oi.order_item_id, oi.shop_id, oi.product_id, oi.quantity, p.product_name
     FROM order_items oi
     JOIN products p ON p.product_id = oi.product_id
     WHERE oi.order_id = $1`,
    [orderId]
  );

  if (items.length === 0) return;

  // Seller notifications — one per item, addressed to that item's shop owner.
  for (const item of items) {
    const shopOwnerId = await notificationModel.getShopOwnerIdByShopId(item.shop_id);
    if (!shopOwnerId) continue; // shop has no owner on record — skip, don't break the order flow

    await notificationModel.createNotification({
      notificationType: 'new_order',
      shopOwnerId,
      orderId,
      orderItemId: item.order_item_id,
      title: 'New order received',
      message: `New order for product #${item.product_id} (${item.product_name}) x${item.quantity}`,
    });
  }

  // Admin notifications — one per active admin, order-level (order_item_id null).
  const adminIds = await notificationModel.getActiveAdminIds();
  const shopCount = new Set(items.map((i) => i.shop_id)).size;
  for (const adminId of adminIds) {
    await notificationModel.createNotification({
      notificationType: 'new_order',
      adminId,
      orderId,
      title: 'New order placed',
      message: `Order #${orderId} placed — ${items.length} item(s) across ${shopCount} shop(s)`,
    });
  }
}

// Human-readable message per status — exact wording from the THIRAA order
// management spec. Add more entries here if you introduce new statuses.
//
// Cancelled has two voices: when the CUSTOMER cancelled their own item,
// the notification is really just a receipt of their own action ("by
// you"), not news about something the shop did. `extra.cancelledBy`
// ('customer' | 'shop') decides which wording is used.
const CUSTOMER_STATUS_MESSAGES = {
  Processing: () => `Your order has been confirmed by the shop.`,
  Cancelled: (productId, extra) => {
    const who = extra?.cancelledBy === 'customer' ? 'by you' : 'by the shop';
    return extra?.cancellationReason
      ? `Your order has been cancelled ${who}. Reason: ${extra.cancellationReason}`
      : `Your order has been cancelled ${who}.`;
  },
  Packed: () => `Your order has been packed.`,
  Shipped: () => `Your order has been shipped.`,
  Delivered: () => `Your order has been delivered successfully.`,
};

const CUSTOMER_STATUS_TITLES = {
  Processing: 'Order Confirmed',
  Cancelled: 'Order Cancelled',
  Packed: 'Order Packed',
  Shipped: 'Order Shipped',
  Delivered: 'Order Delivered',
};

function buildCustomerMessage(productId, newStatus, extra) {
  const builder = CUSTOMER_STATUS_MESSAGES[newStatus];
  return builder ? builder(productId, extra) : `Your order's product #${productId} is now ${newStatus}`;
}

// ── Trigger B: order_item status changed ────────────────────────────────
// Call this once, right after an order_item's item_status is successfully
// updated (seller decision OR fulfillment step). Notifies:
//   - the customer who placed the order (item-level)
//   - EVERY active admin (item-level)
// `extra` currently only carries { cancellationReason, cancelledBy } for
// the Cancelled case — kept generic so future statuses can pass their own
// extra context without changing this function's signature again.
async function notifyItemStatusChange(orderItemId, newStatus, extra = {}) {
  const { rows } = await pool.query(
    `SELECT oi.order_item_id, oi.order_id, oi.product_id, oi.quantity, p.product_name, o.customer_id
     FROM order_items oi
     JOIN products p ON p.product_id = oi.product_id
     JOIN orders o ON o.order_id = oi.order_id
     WHERE oi.order_item_id = $1`,
    [orderItemId]
  );
  const item = rows[0];
  if (!item) return;

  await notificationModel.createNotification({
    notificationType: 'status_update',
    customerId: item.customer_id,
    orderId: item.order_id,
    orderItemId: item.order_item_id,
    title: CUSTOMER_STATUS_TITLES[newStatus] || 'Order update',
    message: buildCustomerMessage(item.product_id, newStatus, extra),
  });

  const adminIds = await notificationModel.getActiveAdminIds();
  for (const adminId of adminIds) {
    await notificationModel.createNotification({
      notificationType: 'status_update',
      adminId,
      orderId: item.order_id,
      orderItemId: item.order_item_id,
      title: 'Item status updated',
      message: `Order #${item.order_id} — product #${item.product_id} (${item.product_name}) moved to ${newStatus}`,
    });
  }
}

module.exports = { isValidTransition, notifyNewOrder, notifyItemStatusChange };