const pool = require('../../config/db');

// Shared SELECT — one row per order_item, with everything a shop owner's
// order card/details screen needs (product, variant, customer's delivery
// address, order-level payment info). Deliberately does NOT filter by
// item_status here — callers add that in WHERE so both "list" (optionally
// filtered) and "single order" (never filtered) can share this shape.
const BASE_SELECT = `
    SELECT
        oi.order_item_id,
        oi.order_id,
        oi.shop_id,
        oi.product_id,
        oi.variant_id,
        oi.quantity,
        oi.price,
        oi.item_status,
        oi.cancellation_reason,
        oi.cancelled_at,
        oi.cancelled_by,
        oi.created_at AS item_created_at,
        oi.updated_at AS item_updated_at,

        p.product_name,
        p.mrp AS product_mrp,

        pv.size AS variant_size,
        pv.stock_quantity,

        pc.color_name,
        pc.color_hex,

        o.customer_id,
        o.payment_method,
        o.payment_status,
        o.order_status,
        o.created_at AS order_created_at,

        a.full_name AS delivery_name,
        a.phone AS delivery_phone,
        a.address_line1,
        a.address_line2,
        a.city AS delivery_city,
        a.state AS delivery_state,
        a.country AS delivery_country,
        a.pincode AS delivery_pincode,

        img.image_url AS product_image

    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN product_variants pv ON pv.variant_id = oi.variant_id
    LEFT JOIN product_colors pc ON pc.product_color_id = pv.product_color_id
    LEFT JOIN addresses a ON a.address_id = o.address_id
    LEFT JOIN LATERAL (
        SELECT image_url
        FROM product_images
        WHERE product_id = oi.product_id
          AND (product_color_id = pv.product_color_id OR product_color_id IS NULL)
          AND image_type != '360'
        ORDER BY display_order ASC, image_id ASC
        LIMIT 1
    ) img ON TRUE
`;

// GET /api/shop-owner/orders?status=Pending  (status omitted -> all statuses)
// "New Orders" tab passes status=Pending, "Processing"/"Packed"/"Shipped"/
// "Delivered"/"Cancelled" tabs pass their own literal status.
exports.listOrders = async (shopId, status) => {
  const params = [shopId];
  let filter = '';
  if (status) {
    params.push(status);
    filter = `AND oi.item_status = $${params.length}`;
  }

  const { rows } = await pool.query(
    `${BASE_SELECT} WHERE oi.shop_id = $1 ${filter} ORDER BY oi.created_at DESC`,
    params
  );
  return rows;
};

// GET /api/shop-owner/orders/:orderId
// All of THIS shop's items within that order (a multi-vendor order may
// have items from other shops too — those are simply never returned here,
// per the WHERE oi.shop_id = $2).
exports.getOrderById = async (shopId, orderId) => {
  const { rows } = await pool.query(
    `${BASE_SELECT} WHERE oi.order_id = $1 AND oi.shop_id = $2 ORDER BY oi.order_item_id ASC`,
    [orderId, shopId]
  );
  return rows;
};

// GET /api/shop-owner/orders/items/:orderItemId  (single item — used by
// notification "tap to view" deep-links)
exports.getOrderItemById = async (shopId, orderItemId) => {
  const { rows } = await pool.query(
    `${BASE_SELECT} WHERE oi.order_item_id = $1 AND oi.shop_id = $2`,
    [orderItemId, shopId]
  );
  return rows[0] || null;
};
