const express = require('express');
const router = express.Router();

const productController = require('../../controllers/admin/product.controller');

// ⚠️ Adjust this import to match whatever admin-auth middleware your app
// already uses elsewhere (the one that verifies the admin JWT sent as
// `Authorization: Bearer <token>` by ApiService.headers).
const adminAuth = require('../../middleware/adminAuth');

// GET /api/admin/products
// Optional query params: shopId, categoryId, isActive, search
router.get('/', adminAuth, productController.getAllProducts);

// GET /api/admin/products/:productId
router.get('/:productId', adminAuth, productController.getProductById);

// GET /api/admin/product/:productId/status
router.patch('/:productId/status', adminAuth, productController.updateProductStatus);

module.exports = router;

// Mount this in your main admin router, e.g.:
//   const productRoutes = require('./routes/admin/product.routes');
//   app.use('/api/admin/products', productRoutes);