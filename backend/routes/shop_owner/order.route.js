
const express = require("express");
const router = express.Router();

const orderController = require("../../controllers/shop_owner/order.controller");
const shopOwnerAuth = require("../../middleware/shopownerauth");

// GET /api/shop-owner/orders
router.get("/", shopOwnerAuth, orderController.getOrders);

module.exports = router;
