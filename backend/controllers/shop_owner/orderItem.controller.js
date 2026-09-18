const orderItemService = require('../../services/shared/orderItem.service');

// PATCH /api/shop-owner/order-items/:orderItemId/status
// body: { status: 'Accepted' | 'Hold' | 'Cancelled' | 'Started' | 'Packed' | 'Shipped' | 'Delivered' }
//
// If you already have an existing endpoint for accepting/progressing
// order items, wire orderItemService.updateItemStatus(...) into that
// instead of adding this as a second route — the important part is that
// every status change goes through this one service function so the
// transition validation + notification dispatch always runs.
exports.updateItemStatus = async (req, res) => {
  try {
    const { orderItemId } = req.params;
    const { status } = req.body;
    // Same field-name convention as customerAuth (req.customer.customerId)
    // — confirm this matches your actual shopOwnerAuth middleware.
    const shopOwnerId = req.shopOwner.shopOwnerId;

    if (!status) {
      return res.status(400).json({ success: false, message: 'status is required' });
    }

    const updated = await orderItemService.updateItemStatus(orderItemId, status, shopOwnerId);
    res.json({ success: true, data: updated });
  } catch (err) {
    if (err.statusCode) {
      return res.status(err.statusCode).json({ success: false, message: err.message });
    }
    console.error('[shop_owner updateItemStatus]', err);
    res.status(500).json({ success: false, message: 'Failed to update item status' });
  }
};