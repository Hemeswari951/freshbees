const express    = require('express');
const router     = express.Router();
const adminAuth  = require('../../middleware/adminauth');
const ctrl       = require('../../controllers/admin/shops.controller');
const {upload, handleUploadError } = require('../../middleware/upload');

// All admin shop routes require a valid admin JWT
router.use(adminAuth);

// GET  /api/admin/shops         → ShopsScreen (grid + 3 stat cards)
router.get('/', ctrl.listShops);

// GET  /api/admin/shops/:id     → ShopDetailScreen
router.get('/:id', ctrl.getShop);

// POST /api/admin/shops         → AddShopScreen "Save shop"
// multer fields: 'logo' (1 file) and 'banner' (1 file)

router.post(
  '/',
  upload.fields([
    { name: 'logo',   maxCount: 1 },
    { name: 'banner', maxCount: 1 },
  ]),
  handleUploadError,
  ctrl.createShop
);

// PATCH /api/admin/shops/:id/status  → ShopDetailScreen Block/Unblock button
router.patch('/:id/status', ctrl.updateShopStatus);

// Update Shop Details
router.patch('/:id/basic', ctrl.updateBasicInfo);
router.patch('/:id/owner', ctrl.updateOwnerInfo);
router.patch('/:id/bank', ctrl.updateBankInfo);
router.patch('/:id/settings', ctrl.updateSettings);

module.exports = router;