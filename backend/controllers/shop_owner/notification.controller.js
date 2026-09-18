const notificationModel = require('../../models/shared/notification.model');

// shopOwnerAuth almost certainly sets req.shopOwner.shopOwnerId (camelCase),
// following the same convention customerAuth uses (req.customer.customerId)
// — NOT req.shopOwner.id. Confirm against your actual middleware.
function getShopOwnerId(req) {
  return req.shopOwner.shopOwnerId;
}

// GET /api/shop-owner/notifications?page=1&limit=20&isRead=false
exports.listNotifications = async (req, res) => {
  try {
    const shopOwnerId = getShopOwnerId(req);
    const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 50);
    const page = Math.max(Number(req.query.page) || 1, 1);
    const offset = (page - 1) * limit;
    const isRead = req.query.isRead === undefined ? undefined : req.query.isRead === 'true';

    const rows = await notificationModel.findByRecipient({
      column: 'shop_owner_id',
      recipientId: shopOwnerId,
      isRead,
      limit,
      offset,
    });
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('[shop_owner listNotifications]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
  }
};

// GET /api/shop-owner/notifications/unread-count
exports.unreadCount = async (req, res) => {
  try {
    const shopOwnerId = getShopOwnerId(req);
    const count = await notificationModel.countUnread({ column: 'shop_owner_id', recipientId: shopOwnerId });
    res.json({ success: true, data: { count } });
  } catch (err) {
    console.error('[shop_owner unreadCount]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch unread count' });
  }
};

// PATCH /api/shop-owner/notifications/:notificationId/read
exports.markRead = async (req, res) => {
  try {
    const shopOwnerId = getShopOwnerId(req);
    const { notificationId } = req.params;
    const updated = await notificationModel.markRead({
      column: 'shop_owner_id',
      recipientId: shopOwnerId,
      notificationId,
    });
    if (!updated) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.json({ success: true, data: updated });
  } catch (err) {
    console.error('[shop_owner markRead]', err);
    res.status(500).json({ success: false, message: 'Failed to mark as read' });
  }
};

// PATCH /api/shop-owner/notifications/read-all
exports.markAllRead = async (req, res) => {
  try {
    const shopOwnerId = getShopOwnerId(req);
    await notificationModel.markAllRead({ column: 'shop_owner_id', recipientId: shopOwnerId });
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (err) {
    console.error('[shop_owner markAllRead]', err);
    res.status(500).json({ success: false, message: 'Failed to mark all as read' });
  }
};