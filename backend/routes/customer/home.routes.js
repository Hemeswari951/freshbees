const express = require('express');
const router = express.Router();

const homeController = require('../../controllers/customer/home.controller');

// GET /shops                 -> every shop (Home "All" tab)
// GET /shops?category=men    -> filtered by category (Home "Men" tab, etc)
router.get('/get-shops', homeController.getShops);

// GET /shops/:id              -> single shop, for detail-page fallback fetches
// router.get('/:id', homeController.getShopById);

module.exports = router;