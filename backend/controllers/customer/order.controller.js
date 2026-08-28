const orderModel = require("../../models/customer/order.model");
const cartModel = require("../../models/customer/cart.model");
const addressModel = require("../../models/customer/address.model");

exports.placeOrder = async (req, res) => {

    try {

        const { product_id, variant_id, quantity } = req.body;

        if (!product_id || !quantity) {
            return res.status(400).json({
                success: false,
                message: "product_id and quantity are required"
            });
        }

        const productInfo = await orderModel.getProductForOrder(product_id, variant_id);

        if (!productInfo) {
            return res.status(404).json({
                success: false,
                message: "Product not found"
            });
        }

        const { orderId, orderItemId } = await orderModel.createOrder(
            req.customer.customerId,
            product_id,
            variant_id,
            quantity,
            productInfo.shopId,
            productInfo.price
        );

        return res.status(201).json({
            success: true,
            message: "Order placed successfully",
            order_id: orderId,
            order_item_id: orderItemId
        });

    } catch (err) {

        console.log("Place Order Error:", err);

        return res.status(err.statusCode || 500).json({
            success: false,
            message: err.message || "Server Error"
        });

    }

};

// POST /api/customer/orders/checkout  { cart_item_ids?: number[], address_id: number, payment_method: string }
// "Buy Now" from the Cart screen, now going through the Address + Payment
// screens first. If cart_item_ids is omitted, the whole bag is checked
// out. Prices/stock are re-checked against the DB at this moment (never
// trusted from the cart row) so a stale cart never overcharges or
// undercharges the customer.
//
// UPDATED: address_id is now required and validated against the logged-in
// customer's own address book before an order can be created against it —
// previously no address was collected at all, so orders had address_id
// NULL and payment_method hardcoded to "COD" regardless of what (if
// anything) the customer chose.
exports.checkoutCart = async (req, res) => {

    try {

        const { cart_item_ids, address_id, payment_method } = req.body;

        if (!address_id) {
            return res.status(400).json({
                success: false,
                message: "Please select a delivery address"
            });
        }

        const address = await addressModel.getAddressById(req.customer.customerId, address_id);
        if (!address) {
            return res.status(400).json({
                success: false,
                message: "Selected address was not found"
            });
        }

        const cartRows = await cartModel.getCartItemsForCheckout(req.customer.customerId, cart_item_ids);

        if (!cartRows.length) {
            return res.status(400).json({
                success: false,
                message: "Your bag is empty"
            });
        }

        const items = [];
        for (const row of cartRows) {
            const productInfo = await orderModel.getProductForOrder(row.product_id, row.variant_id);
            if (!productInfo) continue; // product was removed/unlisted since it was added — skip it

            items.push({
                productId: row.product_id,
                variantId: row.variant_id,
                quantity: row.quantity,
                shopId: productInfo.shopId,
                price: productInfo.price
            });
        }

        if (!items.length) {
            return res.status(400).json({
                success: false,
                message: "None of the items in your bag are available anymore"
            });
        }

        const { orderId, orderItemIds } = await orderModel.createOrderFromItems(
            req.customer.customerId,
            items,
            address_id,
            payment_method
        );

        // Only clear the rows that actually made it into the order.
        await cartModel.clearCartItems(req.customer.customerId, cartRows.map((r) => r.cart_item_id));

        return res.status(201).json({
            success: true,
            message: "Order placed successfully",
            order_id: orderId,
            order_item_ids: orderItemIds,
            payment_method: payment_method || "COD"
        });

    } catch (err) {

        console.log("Checkout Cart Error:", err);

        return res.status(err.statusCode || 500).json({
            success: false,
            message: err.message || "Server Error"
        });

    }

};


exports.getMyOrders = async (req, res) => {
    try {
        const orders = await orderModel.getCustomerOrders(
            req.customer.customerId
        );

        return res.status(200).json({
            success: true,
            data: orders
        });

    } catch (err) {
        console.log("Get My Orders Error:", err);

        return res.status(err.statusCode || 500).json({
            success: false,
            message: err.message || "Server Error"
        });
    }
};
