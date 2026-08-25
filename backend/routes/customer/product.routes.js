const express = require('express');
const router = express.Router();

const productController = require('../../controllers/customer/product.controller');

// GET /api/customer/products/meta/filter-options
// MUST be declared before '/:id' — otherwise Express matches
// "filter-options" as an :id param instead of this dedicated route.
router.get('/meta/filter-options', productController.getFilterOptions);

// GET /api/customer/products       → all products from active shops
router.get('/', productController.listProducts);

// GET /api/customer/products/:id   → single product detail (PDP)
router.get('/:id', productController.getProduct);

module.exports = router;