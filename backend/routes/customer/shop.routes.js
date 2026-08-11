
const express = require('express');
const router = express.Router();

const shopController = require('../../controllers/customer/shop.controller');

// GET /api/customer/shops        → list active shops (Nearby Shops)
router.get('/', shopController.listShops);

// GET /api/customer/shops/:id    → single shop detail
router.get('/:id', shopController.getShop);

module.exports = router;
