// backend/routes/customer/wishlist.routes.js
const express = require('express');
const router = express.Router();

const wishlistController = require('../../controllers/customer/wishlist.controller');
const customerAuth = require('../../middleware/customerauth');

// Every wishlist route needs a logged-in customer.
router.use(customerAuth);

// GET /api/customer/wishlist               → every wishlisted product
router.get('/', wishlistController.listWishlist);

// POST /api/customer/wishlist/:productId   → add a product
router.post('/:productId', wishlistController.addToWishlist);

// DELETE /api/customer/wishlist/:productId → remove a product
router.delete('/:productId', wishlistController.removeFromWishlist);

module.exports = router;