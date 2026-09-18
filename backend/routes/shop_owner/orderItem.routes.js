const express = require('express');
const router = express.Router();

const orderItemController = require('../../controllers/shop_owner/orderItem.controller');
// TODO: point this at your actual shop-owner auth middleware.
const shopOwnerAuth = require('../../middleware/shopownerauth');

router.patch('/:orderItemId/status', shopOwnerAuth, orderItemController.updateItemStatus);

module.exports = router;