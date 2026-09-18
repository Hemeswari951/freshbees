const notificationModel = require('../../models/shared/notification.model');

// adminAuth almost certainly sets req.admin.adminId (camelCase), following
// the same convention customerAuth uses (req.customer.customerId) — NOT
// req.admin.id. Confirm against your actual middleware; this was the
// exact bug that made shop-owner/admin notification lists come back empty.
function getAdminId(req) {
  return req.admin.adminId;
}

// GET /api/admin/notifications?page=1&limit=20&isRead=false
exports.listNotifications = async (req, res) => {
  try {
    const adminId = getAdminId(req);
    const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 50);
    const page = Math.max(Number(req.query.page) || 1, 1);
    const offset = (page - 1) * limit;
    const isRead = req.query.isRead === undefined ? undefined : req.query.isRead === 'true';

    const rows = await notificationModel.findByRecipient({
      column: 'admin_id',
      recipientId: adminId,
      isRead,
      limit,
      offset,
    });
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('[admin listNotifications]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
  }
};

// GET /api/admin/notifications/unread-count
exports.unreadCount = async (req, res) => {
  try {
    const adminId = getAdminId(req);
    const count = await notificationModel.countUnread({ column: 'admin_id', recipientId: adminId });
    res.json({ success: true, data: { count } });
  } catch (err) {
    console.error('[admin unreadCount]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch unread count' });
  }
};

// PATCH /api/admin/notifications/:notificationId/read
exports.markRead = async (req, res) => {
  try {
    const adminId = getAdminId(req);
    const { notificationId } = req.params;
    const updated = await notificationModel.markRead({ column: 'admin_id', recipientId: adminId, notificationId });
    if (!updated) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.json({ success: true, data: updated });
  } catch (err) {
    console.error('[admin markRead]', err);
    res.status(500).json({ success: false, message: 'Failed to mark as read' });
  }
};

// PATCH /api/admin/notifications/read-all
exports.markAllRead = async (req, res) => {
  try {
    const adminId = getAdminId(req);
    await notificationModel.markAllRead({ column: 'admin_id', recipientId: adminId });
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (err) {
    console.error('[admin markAllRead]', err);
    res.status(500).json({ success: false, message: 'Failed to mark all as read' });
  }
};