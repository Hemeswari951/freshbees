// routes/shop_owner/profile.route.js

const express = require('express');
const router = express.Router();

const shopController = require('../../controllers/shop_owner/profile.controller');
const shopOwnerAuth = require('../../middleware/shopownerauth');
const { upload, handleUploadError } = require('../../middleware/upload');

// GET  /api/shop-owner/profile  -> shop info + live product/order/rating counts
router.get('/', shopOwnerAuth, shopController.getProfile);

// PUT  /api/shop-owner/profile  -> update shop name/owner name and/or
// logo/banner images (multipart/form-data, fields: logo, banner)
router.put(
  '/',
  shopOwnerAuth,
  upload.any(),
  handleUploadError,
  shopController.updateProfile
);

// GET  /api/shop-owner/reviews  -> paginated review list for this shop's products
router.get('/reviews', shopOwnerAuth, shopController.getReviews);

module.exports = router;