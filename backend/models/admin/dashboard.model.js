const pool = require("../../config/db");

// Get dashboard data

async function totalUsers() {
    try {
        const [rows] = await pool.query(`
            SELECT COUNT(*) AS total_users
            FROM users
        `);
        return rows[0].total_users;
    } catch (err) {
        console.error("[totalUsers]", err);
        throw new Error("Failed to fetch total users");
    }
}

async function totalShops() {
    try {
        const [rows] = await pool.query(`
            SELECT COUNT(*) AS total_shops
            FROM shops
        `);
        return rows[0].total_shops;
    } catch (err) {
        console.error("[totalShops]", err);
        throw new Error("Failed to fetch total shops");
    }
}

async function totalOrders() {
    try {
        const [rows] = await pool.query(`
            SELECT COUNT(*) AS total_orders
            FROM orders
        `);
        return rows[0].total_orders;
    } catch (err) {
        console.error("[totalOrders]", err);
        throw new Error("Failed to fetch total orders");
    }
}

async function totalProducts() {
    try {
        const [rows] = await pool.query(`
            SELECT COUNT(*) AS total_products
            FROM products
        `);
        return rows[0].total_products;
    } catch (err) {
        console.error("[totalProducts]", err);
        throw new Error("Failed to fetch total products");
    }
}

async function totalRevenue() {
    try {
        const [rows] = await pool.query(`
            SELECT SUM(total_amount) AS total_revenue
            FROM orders
            WHERE status = 'completed'
        `);
        return rows[0].total_revenue || 0;
    } catch (err) {
        console.error("[totalRevenue]", err);
        throw new Error("Failed to fetch total revenue");
    }
}

module.exports = {
    totalUsers,
    totalShops,
    totalOrders,
    totalProducts,
    totalRevenue,
};