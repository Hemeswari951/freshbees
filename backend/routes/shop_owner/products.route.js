const express = require("express");
const router = express.Router();
const productsController = require("../../controllers/shop_owner/products.controller");
const shopOwnerAuth = require("../../middleware/shopownerauth");
const { validateProductImageFields, upload, handleUploadError } = require("../../middleware/upload");

// Categories + brands for the Add Product form's dropdowns.
// NOTE: registered BEFORE '/:id' so "meta" isn't parsed as a product id.
router.get('/meta/lookup', shopOwnerAuth, productsController.getMeta);
router.get('/', shopOwnerAuth, productsController.getAllProducts);
router.get('/:id', shopOwnerAuth, productsController.getProductById);

// multipart/form-data: text fields (productName, price, colors JSON, ...)
// plus dynamic file fields color_<index>_<front|back|side|zoom>.
// .any() replaces the old .array('images', 6) because we no longer know the
// field names ahead of time — they depend on how many colors the owner adds.
router.post('/', shopOwnerAuth, upload.any(), validateProductImageFields, handleUploadError, productsController.createProduct);

// Edit flow — ALSO multipart now, same as POST, since the owner may
// replace/add photos while editing (new file fields color_<index>_<angle>
// / color_<index>_360_<frame>) alongside the JSON `colors` field that
// carries existingImages/existingSpin360 (which photos to keep).
router.put('/:id', shopOwnerAuth, upload.any(), validateProductImageFields, handleUploadError, productsController.updateProduct);

router.patch('/:id/status', shopOwnerAuth, productsController.updateProductStatus);

// Manage stock screen — restock (delta > 0) or correction (delta < 0) on one
// existing variant. Does NOT go through the Add Product wizard.
router.patch('/variants/:variantId/stock', shopOwnerAuth, productsController.adjustStock);

router.delete('/:id', shopOwnerAuth, productsController.deleteProduct);

module.exports = router;