const notificationModel = require('../../models/shared/notification.model');

// customerAuth sets req.customer.customerId (camelCase) — confirmed
// earlier from your actual middleware, not req.customer.id.
function getCustomerId(req) {
  return req.customer.customerId;
}

// GET /api/customer/notifications?page=1&limit=20&isRead=false
exports.listNotifications = async (req, res) => {
  try {
    const customerId = getCustomerId(req);
    const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 50);
    const page = Math.max(Number(req.query.page) || 1, 1);
    const offset = (page - 1) * limit;
    const isRead = req.query.isRead === undefined ? undefined : req.query.isRead === 'true';

    const rows = await notificationModel.findByRecipient({
      column: 'customer_id',
      recipientId: customerId,
      isRead,
      limit,
      offset,
    });
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('[customer listNotifications]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
  }
};

// GET /api/customer/notifications/unread-count
exports.unreadCount = async (req, res) => {
  try {
    const customerId = getCustomerId(req);
    const count = await notificationModel.countUnread({ column: 'customer_id', recipientId: customerId });
    res.json({ success: true, data: { count } });
  } catch (err) {
    console.error('[customer unreadCount]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch unread count' });
  }
};

// PATCH /api/customer/notifications/:notificationId/read
exports.markRead = async (req, res) => {
  try {
    const customerId = getCustomerId(req);
    const { notificationId } = req.params;
    const updated = await notificationModel.markRead({
      column: 'customer_id',
      recipientId: customerId,
      notificationId,
    });
    if (!updated) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.json({ success: true, data: updated });
  } catch (err) {
    console.error('[customer markRead]', err);
    res.status(500).json({ success: false, message: 'Failed to mark as read' });
  }
};

// PATCH /api/customer/notifications/read-all
exports.markAllRead = async (req, res) => {
  try {
    const customerId = getCustomerId(req);
    await notificationModel.markAllRead({ column: 'customer_id', recipientId: customerId });
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (err) {
    console.error('[customer markAllRead]', err);
    res.status(500).json({ success: false, message: 'Failed to mark all as read' });
  }
};