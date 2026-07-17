const pool = require("../../config/db");

exports.getShopByOwnerId = async (shopOwnerId) => {
    const result = await pool.query(
        `SELECT so.shop_id, so.full_name, s.shop_name
         FROM shop_owners so
         JOIN shops s ON so.shop_id = s.shop_id
         WHERE so.shop_owner_id = $1`,
        [shopOwnerId]
    );
    return result.rows[0];
};

exports.getTotalOrders = async (shopId) => {
    const result = await pool.query(
        `SELECT COUNT(*) FROM order_items WHERE shop_id = $1`,
        [shopId]
    );
    return parseInt(result.rows[0].count);
};

exports.getOrdersInRange = async (shopId, startInterval, endInterval) => {
    const query = endInterval
        ? `SELECT COUNT(*) FROM order_items
           WHERE shop_id = $1 AND created_at >= NOW() - INTERVAL '${startInterval}' 
           AND created_at < NOW() - INTERVAL '${endInterval}'`
        : `SELECT COUNT(*) FROM order_items 
           WHERE shop_id = $1 AND created_at >= NOW() - INTERVAL '${startInterval}'`;

    const result = await pool.query(query, [shopId]);
    return parseInt(result.rows[0].count);
};

exports.getSalesForDate = async (shopId, dateCondition) => {
    const result = await pool.query(
        `SELECT COALESCE(SUM(price * quantity), 0) as total
         FROM order_items 
         WHERE shop_id = $1 AND created_at::date = ${dateCondition}`,
        [shopId]
    );
    return parseFloat(result.rows[0].total);
};

exports.getPendingOrders = async (shopId) => {
    const result = await pool.query(
        `SELECT COUNT(*) FROM order_items 
         WHERE shop_id = $1 AND item_status = 'Processing'`,
        [shopId]
    );
    return parseInt(result.rows[0].count);
};

exports.getPendingOver24h = async (shopId) => {
    const result = await pool.query(
        `SELECT COUNT(*) FROM order_items 
         WHERE shop_id = $1 AND item_status = 'Processing' 
         AND created_at < NOW() - INTERVAL '24 hours'`,
        [shopId]
    );
    return parseInt(result.rows[0].count);
};

exports.getMonthRevenue = async (shopId) => {
    const result = await pool.query(
        `SELECT COALESCE(SUM(price * quantity), 0) as total
         FROM order_items 
         WHERE shop_id = $1 
         AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)`,
        [shopId]
    );
    return parseFloat(result.rows[0].total);
};

exports.getLowStockProducts = async (shopId) => {
    const result = await pool.query(
        `SELECT p.product_id, p.product_name, COALESCE(SUM(pv.stock_quantity), 0) as total_stock
         FROM products p
         LEFT JOIN product_variants pv ON pv.product_id = p.product_id
         WHERE p.shop_id = $1
         GROUP BY p.product_id, p.product_name
         HAVING COALESCE(SUM(pv.stock_quantity), 0) < 10`,
        [shopId]
    );
    return result.rows;
};

exports.getNextPayout = async (shopId) => {
    const result = await pool.query(
        `SELECT amount, requested_at, status
         FROM payouts
         WHERE shop_id = $1 AND status = 'Pending'
         ORDER BY requested_at ASC
         LIMIT 1`,
        [shopId]
    );
    return result.rows[0] || null;
};

// exports.getBestSellers = async (shopId) => {
//     const result = await pool.query(
//         `SELECT p.product_id, p.product_name, 
//                 SUM(oi.quantity) as total_sold,
//                 pi.image_url
//          FROM order_items oi
//          JOIN products p ON p.product_id = oi.product_id
//          LEFT JOIN LATERAL (
//              SELECT image_url FROM product_images 
//              WHERE product_id = p.product_id 
//              ORDER BY display_order LIMIT 1
//          ) pi ON true
//          WHERE oi.shop_id = $1 AND oi.created_at >= NOW() - INTERVAL '7 days'
//          GROUP BY p.product_id, p.product_name, pi.image_url
//          ORDER BY total_sold DESC
//          LIMIT 3`,
//         [shopId]
//     );
//     return result.rows;
// };

// exports.getRecentOrders = async (shopId) => {
//     const result = await pool.query(
//         `SELECT oi.order_item_id, o.order_id, oi.item_status,
//                 oi.price, oi.quantity, oi.created_at,
//                 c.first_name, c.last_name,
//                 (SELECT COUNT(*) FROM order_items WHERE order_id = o.order_id) as item_count
//          FROM order_items oi
//          JOIN orders o ON o.order_id = oi.order_id
//          JOIN customers c ON c.customer_id = o.customer_id
//          WHERE oi.shop_id = $1
//          ORDER BY oi.created_at DESC
//          LIMIT 3`,
//         [shopId]
//     );
//     return result.rows;
// };