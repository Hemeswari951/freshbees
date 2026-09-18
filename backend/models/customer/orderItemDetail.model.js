const pool = require('../../config/db');

// ── Full detail for ONE order item — product, shop, payment, address ─────
// Ownership-checked via o.customer_id = $2, so a customer can never fetch
// another customer's order item by guessing an id.
async function getOrderItemDetail(orderItemId, customerId) {
  const { rows } = await pool.query(
    `
    SELECT
      oi.order_item_id,
      oi.order_id,
      oi.product_id,
      oi.variant_id,
      oi.quantity,
      oi.price,
      oi.item_status,
      oi.cancellation_reason,
      oi.created_at AS item_created_at,
      oi.updated_at AS item_updated_at,

      o.total_amount,
      o.payment_method,
      o.payment_status,
      o.order_status,
      o.created_at AS order_created_at,

      p.product_name,

      pv.size AS variant_size,

      s.shop_id,
      s.shop_name,

      COALESCE(img.image_url, NULL) AS thumbnail,

      a.full_name AS address_full_name,
      a.phone AS address_phone,
      a.address_line1,
      a.address_line2,
      a.city,
      a.state,
      a.pincode,
      a.country
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN product_variants pv ON pv.variant_id = oi.variant_id
    JOIN shops s ON s.shop_id = oi.shop_id
    LEFT JOIN addresses a ON a.address_id = o.address_id
    LEFT JOIN LATERAL (
      SELECT pi.image_url
      FROM product_images pi
      JOIN product_colors pc ON pc.product_color_id = pi.product_color_id
      WHERE pc.product_id = oi.product_id
      ORDER BY pc.created_at ASC,
               CASE pi.image_type WHEN 'front' THEN 0 ELSE 1 END,
               pi.display_order ASC
      LIMIT 1
    ) img ON true
    WHERE oi.order_item_id = $1
      AND o.customer_id = $2
    `,
    [orderItemId, customerId]
  );
  return rows[0] || null;
}

// ── CANCEL (customer-initiated) — Pending -> Cancelled ────────────────────
// Ownership-checked via the same o.customer_id = $2 join as the detail
// query above, so a customer can never cancel another customer's item.
// Mirrors the shop-side lifecycle rule in notification.service.js
// (TRANSITIONS.Pending includes 'Cancelled'; every later state does not) —
// so this only ever succeeds while item_status is still 'Pending', i.e.
// before the shop has confirmed/started preparing it. The status check
// happens INSIDE the UPDATE's WHERE clause so a second concurrent cancel
// (or a cancel arriving just after the shop confirms it) simply updates
// zero rows instead of racing.
//
// `reason` — one of the preset reasons the app shows in its "why are you
// cancelling" sheet (or the customer's own text when they pick "Other").
// Stored in the same cancellation_reason column the shop-owner side
// already writes to, so both flows show up identically wherever that
// column is read.
async function cancelOrderItem(orderItemId, customerId, reason) {
  const { rows } = await pool.query(
    `
    UPDATE order_items oi
    SET item_status = 'Cancelled',
        cancellation_reason = $3,
        cancelled_at = NOW(),
        cancelled_by = 'customer',
        updated_at = NOW()
    FROM orders o
    WHERE oi.order_item_id = $1
      AND oi.order_id = o.order_id
      AND o.customer_id = $2
      AND oi.item_status = 'Pending'
    RETURNING oi.order_item_id, oi.item_status, oi.cancellation_reason
    `,
    [orderItemId, customerId, reason]
  );
  return rows[0] || null;
}

module.exports = { getOrderItemDetail, cancelOrderItem };