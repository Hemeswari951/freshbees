const homeModel = require("../../models/shop_owner/home.model");
const { calculatePercentChange } = require("../../utils/calculatePercentChange");

exports.buildHomeData = async (shopOwnerId) => {
    const shopInfo = await homeModel.getShopByOwnerId(shopOwnerId);

    if (!shopInfo) {
        throw new Error("Shop not found");
    }

    const { shop_id, full_name, shop_name } = shopInfo;

    const [
        totalOrders,
        ordersLastWeek,
        ordersThisWeek,
        todaySales,
        yesterdaySales,
        pendingOrders,
        pendingOver24h,
        monthRevenue,
        lowStockRows,
        nextPayoutRow,
        bestSellerRows,
        recentOrderRows
    ] = await Promise.all([
        homeModel.getTotalOrders(shop_id),
        homeModel.getOrdersInRange(shop_id, '14 days', '7 days'),
        homeModel.getOrdersInRange(shop_id, '7 days', null),
        homeModel.getSalesForDate(shop_id, 'CURRENT_DATE'),
        homeModel.getSalesForDate(shop_id, "CURRENT_DATE - INTERVAL '1 day'"),
        homeModel.getPendingOrders(shop_id),
        homeModel.getPendingOver24h(shop_id),
        homeModel.getMonthRevenue(shop_id),
        homeModel.getLowStockProducts(shop_id),
        homeModel.getNextPayout(shop_id)
        // homeModel.getBestSellers(shop_id),
        // homeModel.getRecentOrders(shop_id)
    ]);

    return {
        owner_name: full_name,
        shop_name: shop_name,
        stats: {
            total_orders: totalOrders,
            orders_change_percent: calculatePercentChange(ordersThisWeek, ordersLastWeek),
            todays_sales: todaySales,
            sales_change_percent: calculatePercentChange(todaySales, yesterdaySales),
            pending_orders: pendingOrders,
            pending_over_24h: pendingOver24h,
            total_revenue: monthRevenue
        },
        low_stock: {
            count: lowStockRows.length,
            products: lowStockRows
        },
        next_payout: nextPayoutRow ? {
            amount: parseFloat(nextPayoutRow.amount),
            requested_at: nextPayoutRow.requested_at
        } : null,

        
        // best_sellers: bestSellerRows.map(row => ({
        //     product_id: row.product_id,
        //     name: row.product_name,
        //     sold_count: parseInt(row.total_sold),
        //     image_url: row.image_url
        // })),
        // recent_orders: recentOrderRows.map(row => ({
        //     order_id: row.order_id,
        //     customer_name: `${row.first_name} ${row.last_name}`,
        //     item_count: parseInt(row.item_count),
        //     price: parseFloat(row.price) * row.quantity,
        //     status: row.item_status,
        //     created_at: row.created_at
        // }))
    };
};