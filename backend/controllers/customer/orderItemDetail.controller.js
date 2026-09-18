const orderItemDetailModel = require('../../models/customer/orderItemDetail.model');
const notificationService = require('../../services/shared/notification.service');

function mapDetail(row) {
  return {
    orderId: row.order_id,
    orderItemId: row.order_item_id,
    productId: row.product_id,
    productName: row.product_name,
    variantSize: row.variant_size,
    quantity: row.quantity,
    price: Number(row.price),
    thumbnail: row.thumbnail || '',
    itemStatus: row.item_status,
    cancellationReason: row.cancellation_reason || null,
    itemCreatedAt: row.item_created_at,
    itemUpdatedAt: row.item_updated_at,

    shopId: row.shop_id,
    shopName: row.shop_name,

    totalAmount: Number(row.total_amount),
    paymentMethod: row.payment_method,
    paymentStatus: row.payment_status,
    orderStatus: row.order_status,
    orderCreatedAt: row.order_created_at,

    address: row.address_full_name
      ? {
          fullName: row.address_full_name,
          phone: row.address_phone,
          addressLine1: row.address_line1,
          addressLine2: row.address_line2,
          city: row.city,
          state: row.state,
          pincode: row.pincode,
          country: row.country,
        }
      : null,
  };
}

// GET /api/customer/orders/items/:orderItemId
exports.getOrderItemDetail = async (req, res) => {
  try {
    const { orderItemId } = req.params;
    const customerId = req.customer.customerId;

    const row = await orderItemDetailModel.getOrderItemDetail(orderItemId, customerId);
    if (!row) {
      return res.status(404).json({ success: false, message: 'Order item not found' });
    }

    res.json({ success: true, data: mapDetail(row) });
  } catch (err) {
    console.error('[customer getOrderItemDetail]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch order item detail' });
  }
};

// Reasons shown in the customer app's "why are you cancelling" sheet.
// Kept here (not hardcoded in the mobile app) so the allowed list can
// change without a client release; the app fetches this via
// GET /api/customer/orders/items/cancel-reasons.
const CANCELLATION_REASONS = [
  'Ordered by mistake',
  'Found a better price elsewhere',
  'Item no longer needed',
  'Delivery time is too long',
  'Wrong size or color selected',
  'Other',
];

// GET /api/customer/orders/items/cancel-reasons
exports.getCancelReasons = async (req, res) => {
  res.json({ success: true, data: CANCELLATION_REASONS });
};

// PUT /api/customer/orders/items/:orderItemId/cancel   body: { reason, customReason? }
// Customer cancelling their OWN item, only while it's still 'Pending' —
// once the shop has confirmed it (Processing/Packed/Shipped/Delivered),
// this intentionally returns 400 and the customer has to go through
// support instead (same rule the shop-owner side enforces).
//
// `reason` must be one of CANCELLATION_REASONS. When it's 'Other', the
// customer's own free-text goes in `customReason` and THAT is what gets
// stored — mirrors the shop-owner cancel flow's reason/customReason shape.
exports.cancelOrderItem = async (req, res) => {
  try {
    const { orderItemId } = req.params;
    const customerId = req.customer.customerId;
    const { reason, customReason } = req.body;

    if (!reason || !CANCELLATION_REASONS.includes(reason)) {
      return res.status(400).json({ success: false, message: 'Please select a valid cancellation reason' });
    }

    const finalReason = reason === 'Other' ? (customReason || '').trim() : reason;

    if (!finalReason) {
      return res.status(400).json({ success: false, message: 'Please tell us why you are cancelling' });
    }

    const updated = await orderItemDetailModel.cancelOrderItem(orderItemId, customerId, finalReason);

    if (!updated) {
      // Either the item doesn't belong to this customer, or it's already
      // past the point where a customer can self-cancel it — check which,
      // so the error message is accurate instead of always saying 404.
      const existing = await orderItemDetailModel.getOrderItemDetail(orderItemId, customerId);

      if (!existing) {
        return res.status(404).json({ success: false, message: 'Order item not found' });
      }

      return res.status(400).json({
        success: false,
        message: `This item is already '${existing.item_status}' and can no longer be cancelled.`,
      });
    }

    await notificationService.notifyItemStatusChange(orderItemId, 'Cancelled', {
      cancellationReason: finalReason,
      cancelledBy: 'customer',
    });

    res.json({
      success: true,
      data: {
        orderItemId: updated.order_item_id,
        itemStatus: updated.item_status,
        cancellationReason: updated.cancellation_reason,
      },
    });
  } catch (err) {
    console.error('[customer cancelOrderItem]', err);
    res.status(500).json({ success: false, message: 'Failed to cancel item' });
  }
};