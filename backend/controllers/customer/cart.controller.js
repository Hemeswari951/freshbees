

// cart.controller.js

const cartModel = require("../../models/customer/cart.model");

// Row → JSON matching what the Flutter Cart screen expects.
function mapCartItem(row) {
    return {
        cartItemId: Number(row.cart_item_id),
        productId: Number(row.product_id),
        variantId: row.variant_id ? Number(row.variant_id) : null,
        productName: row.product_name,
        thumbnail: row.thumbnail || '',
        price: Number(row.price),
        quantity: Number(row.quantity), 
        size: row.size || null,
        stockQuantity: row.stock_quantity != null ? Number(row.stock_quantity) : null,
        lineTotal: Number(row.price) * Number(row.quantity),
    };
}

// GET /api/customer/cart
exports.getCart = async (req, res) => {
    try {
        const rows = await cartModel.getCartByCustomer(req.customer.customerId);
        const items = rows.map(mapCartItem);
        const subtotal = items.reduce((sum, i) => sum + i.lineTotal, 0);
        res.json({ success: true, data: { items, subtotal, itemCount: items.length } });
    } catch (err) {
        console.log("Get Cart Error:", err);
        res.status(500).json({ success: false, message: "Failed to fetch cart" });
    }
};

// POST /api/customer/cart  { product_id, variant_id?, quantity? }
exports.addToCart = async (req, res) => {
    try {
        const { product_id, variant_id, quantity } = req.body;

        if (!product_id) {
            return res.status(400).json({ success: false, message: "product_id is required" });
        }

        const qty = quantity && quantity > 0 ? quantity : 1;
        const cartItemId = await cartModel.addToCart(req.customer.customerId, product_id, variant_id, qty);

        res.status(201).json({ success: true, message: "Added to bag", cart_item_id: cartItemId });
    } catch (err) {
        console.log("Add To Cart Error:", err);
        res.status(500).json({ success: false, message: "Failed to add to bag" });
    }
};

// PUT /api/customer/cart/:id  { quantity }
exports.updateQuantity = async (req, res) => {
    try {
        const cartItemId = Number(req.params.id);
        const { quantity } = req.body;

        if (!quantity || quantity < 1) {
            return res.status(400).json({ success: false, message: "quantity must be at least 1" });
        }

        const updated = await cartModel.updateQuantity(req.customer.customerId, cartItemId, quantity);
        if (!updated) {
            return res.status(404).json({ success: false, message: "Cart item not found" });
        }

        res.json({ success: true, message: "Quantity updated" });
    } catch (err) {
        console.log("Update Cart Error:", err);
        res.status(500).json({ success: false, message: "Failed to update quantity" });
    }
};

// DELETE /api/customer/cart/:id
exports.removeFromCart = async (req, res) => {
    try {
        const cartItemId = Number(req.params.id);
        const removed = await cartModel.removeCartItem(req.customer.customerId, cartItemId);

        if (!removed) {
            return res.status(404).json({ success: false, message: "Cart item not found" });
        }

        res.json({ success: true, message: "Removed from bag" });
    } catch (err) {
        console.log("Remove Cart Item Error:", err);
        res.status(500).json({ success: false, message: "Failed to remove item" });
    }
};
