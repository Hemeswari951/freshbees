

const express = require("express");
const router = express.Router();

const cartController = require("../../controllers/customer/cart.controller");
const customerAuth = require("../../middleware/customerAuth");

// Every cart route needs a logged-in customer.
router.use(customerAuth);

// GET  /api/customer/cart        → items in the bag
router.get("/", cartController.getCart);

// POST /api/customer/cart        { product_id, variant_id?, quantity? } → add / bump qty
router.post("/", cartController.addToCart);

// PUT  /api/customer/cart/:id    { quantity } → change quantity
router.put("/:id", cartController.updateQuantity);

// DELETE /api/customer/cart/:id  → remove one item from the bag
router.delete("/:id", cartController.removeFromCart);

module.exports = router;
