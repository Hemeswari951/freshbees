const express = require('express');
const router = express.Router();

const ordersController = require('../../controllers/shop_owner/orders.controller');
const shopOwnerAuth = require('../../middleware/shopownerauth');

router.use(shopOwnerAuth);

// GET /api/shop-owner/orders?status=Pending
router.get('/', ordersController.listOrders);

// PATCH /api/shop-owner/orders/:orderItemId/confirm|cancel|packed|shipped|delivered
// (declared before the single-segment "/:orderId" GET below so they never
// get shadowed by it — different HTTP method anyway, but kept explicit)
router.patch('/:orderItemId/confirm', ordersController.confirmOrder);
router.patch('/:orderItemId/cancel', ordersController.cancelOrder);
router.patch('/:orderItemId/packed', ordersController.markPacked);
router.patch('/:orderItemId/shipped', ordersController.markShipped);
router.patch('/:orderItemId/delivered', ordersController.markDelivered);

// GET /api/shop-owner/orders/:orderId — this shop's items within that order
router.get('/:orderId', ordersController.getOrderById);

module.exports = router;
