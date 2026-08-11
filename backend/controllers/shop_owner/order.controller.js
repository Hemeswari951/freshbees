
const orderModel = require("../../models/shop_owner/order.model");

exports.getOrders = async (req, res) => {

    try {

        const shopId = req.shopOwner.shopId;

        const orders = await orderModel.getOrdersByShop(shopId);

        return res.status(200).json({
            success: true,
            data: orders
        });

    } catch (err) {

        console.log("Get Orders Error:", err);

        return res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }

};
