const express = require('express');
const router = express.Router();

const homeController = require('../../controllers/customer/home.controller');

// GET /home/get-shops                 -> every shop (Home "All" tab)
// GET /home/get-shops?category=men    -> filtered by category
router.get('/get-shops', homeController.getShops);

// GET /home/shop-detail/:id           -> single shop, for Shop Overview screen
router.get('/shop-detail/:id', homeController.getShopDetail);

module.exports = router;