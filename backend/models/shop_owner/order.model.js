
const pool = require("../../config/db");

exports.getOrdersByShop = async (shopId) => {
    const result = await pool.query(
        `
        SELECT
            oi.order_item_id,
            oi.order_id,
            oi.product_id,
            p.product_name,
            oi.variant_id,
            oi.quantity,
            oi.price,
            oi.item_status,
            oi.created_at,
            c.first_name,
            c.last_name,
            c.email
        FROM order_items oi
        JOIN orders o ON o.order_id = oi.order_id
        JOIN customers c ON c.customer_id = o.customer_id
        JOIN products p ON p.product_id = oi.product_id
        WHERE oi.shop_id = $1
        ORDER BY oi.created_at DESC
        `,
        [shopId]
    );

    return result.rows;
};
