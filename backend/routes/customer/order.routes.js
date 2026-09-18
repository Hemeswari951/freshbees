/*const express = require("express");
const router = express.Router();

const orderController = require("../../controllers/customer/order.controller");
const customerAuth = require("../../middleware/customerauth");

// POST /api/customer/orders  { product_id, variant_id?, quantity }
router.post("/", customerAuth, orderController.placeOrder);

module.exports = router;*/


const express = require("express");
const router = express.Router();

const orderController = require("../../controllers/customer/order.controller");
const customerAuth = require("../../middleware/customerAuth");

// POST /api/customer/orders  { product_id, variant_id?, quantity }
router.post("/", customerAuth, orderController.placeOrder);

// POST /api/customer/orders/checkout  { cart_item_ids? }  → "Buy Now" from the Cart screen
router.post("/checkout", customerAuth, orderController.checkoutCart);

router.get("/", customerAuth, orderController.getMyOrders);

// GET /api/customer/orders/:orderId — MUST stay after "/checkout" above,
// since Express matches routes top-to-bottom and ":orderId" would
// otherwise swallow "/checkout" as if "checkout" were an order id.
router.get("/:orderId", customerAuth, orderController.getOrderById);

module.exports = router;