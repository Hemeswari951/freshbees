const dashboardModel = require("../../models/admin/dashboard.model");

// Get dashboard data
async function getDashboardData() {
    try {
        const [totalUsers, totalShops, totalOrders, totalProducts, totalRevenue] = await Promise.all([
            dashboardModel.totalUsers(),
            dashboardModel.totalShops(),
            dashboardModel.totalOrders(),
            dashboardModel.totalProducts(),
            dashboardModel.totalRevenue(),
        ]);
        return {
            totalUsers,
            totalShops,
            totalOrders,
            totalProducts,
            totalRevenue
        };

    } catch (err) {
        console.error("[getDashboardData]", err);
        throw new Error("Failed to fetch dashboard data");
    }
}

module.exports = {
    getDashboardData,
};