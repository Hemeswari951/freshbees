const express = require('express');
const router = express.Router();

const orderItemDetailController = require('../../controllers/customer/orderItemDetail.controller');
const customerAuth = require('../../middleware/customerAuth');

// GET /api/customer/orders/items/cancel-reasons — MUST stay above
// "/:orderItemId" below, otherwise Express would treat "cancel-reasons"
// as an :orderItemId value.
router.get('/cancel-reasons', customerAuth, orderItemDetailController.getCancelReasons);

// GET /api/customer/orders/items/:orderItemId
router.get('/:orderItemId', customerAuth, orderItemDetailController.getOrderItemDetail);

// PUT /api/customer/orders/items/:orderItemId/cancel   body: { reason, customReason? }
router.put('/:orderItemId/cancel', customerAuth, orderItemDetailController.cancelOrderItem);

module.exports = router;

// Mount in your customer index.js:
//   router.use('/orders/items', require('./orderItemDetail.routes'));