const ordersModel = require('../../models/shop_owner/orders.model');
const orderItemService = require('../../services/shared/orderItem.service');
const { OrderItemError } = orderItemService;

function handleError(res, err, fallback) {
  if (err instanceof OrderItemError || err.statusCode) {
    return res.status(err.statusCode).json({ success: false, message: err.message });
  }
  console.error(fallback, err);
  return res.status(500).json({ success: false, message: fallback });
}

// GET /api/shop-owner/orders?status=Pending
exports.listOrders = async (req, res) => {
  try {
    const { shopId } = req.shopOwner;
    const status = req.query.status || undefined;
    const rows = await ordersModel.listOrders(shopId, status);
    res.json({ success: true, data: rows });
  } catch (err) {
    handleError(res, err, 'Failed to fetch orders');
  }
};

// GET /api/shop-owner/orders/:orderId
exports.getOrderById = async (req, res) => {
  try {
    const { shopId } = req.shopOwner;
    const rows = await ordersModel.getOrderById(shopId, req.params.orderId);
    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, data: rows });
  } catch (err) {
    handleError(res, err, 'Failed to fetch order');
  }
};

// PATCH /api/shop-owner/orders/:orderItemId/confirm
exports.confirmOrder = async (req, res) => {
  try {
    const { shopOwnerId, shopId } = req.shopOwner;
    const updated = await orderItemService.confirmOrder(req.params.orderItemId, shopOwnerId, shopId);
    res.json({ success: true, message: 'Order confirmed', data: updated });
  } catch (err) {
    handleError(res, err, 'Failed to confirm order');
  }
};

// PATCH /api/shop-owner/orders/:orderItemId/cancel   body: { reason, customReason? }
exports.cancelOrder = async (req, res) => {
  try {
    const { shopOwnerId, shopId } = req.shopOwner;
    const { reason, customReason } = req.body;
    const finalReason = reason === 'Other' ? customReason : reason;

    const updated = await orderItemService.cancelOrder(
      req.params.orderItemId,
      shopOwnerId,
      shopId,
      finalReason
    );
    res.json({ success: true, message: 'Order cancelled', data: updated });
  } catch (err) {
    handleError(res, err, 'Failed to cancel order');
  }
};

// PATCH /api/shop-owner/orders/:orderItemId/packed
exports.markPacked = async (req, res) => {
  try {
    const { shopOwnerId, shopId } = req.shopOwner;
    const updated = await orderItemService.markPacked(req.params.orderItemId, shopOwnerId, shopId);
    res.json({ success: true, message: 'Order marked as packed', data: updated });
  } catch (err) {
    handleError(res, err, 'Failed to update order');
  }
};

// PATCH /api/shop-owner/orders/:orderItemId/shipped
exports.markShipped = async (req, res) => {
  try {
    const { shopOwnerId, shopId } = req.shopOwner;
    const updated = await orderItemService.markShipped(req.params.orderItemId, shopOwnerId, shopId);
    res.json({ success: true, message: 'Order marked as shipped', data: updated });
  } catch (err) {
    handleError(res, err, 'Failed to update order');
  }
};

// PATCH /api/shop-owner/orders/:orderItemId/delivered
exports.markDelivered = async (req, res) => {
  try {
    const { shopOwnerId, shopId } = req.shopOwner;
    const updated = await orderItemService.markDelivered(req.params.orderItemId, shopOwnerId, shopId);
    res.json({ success: true, message: 'Order marked as delivered', data: updated });
  } catch (err) {
    handleError(res, err, 'Failed to update order');
  }
};
