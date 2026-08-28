
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

module.exports = router;

