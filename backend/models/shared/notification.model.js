const pool = require('../../config/db');

// The only 3 valid recipient columns — never build this from req input,
// only ever pass one of these 3 literal strings from the service/
// controller layer. Keeps the string-interpolated SQL below safe.
const RECIPIENT_COLUMNS = ['admin_id', 'shop_owner_id', 'customer_id'];

function assertValidColumn(column) {
  if (!RECIPIENT_COLUMNS.includes(column)) {
    throw new Error(`Invalid notification recipient column: ${column}`);
  }
}

async function createNotification({
  notificationType,
  adminId = null,
  shopOwnerId = null,
  customerId = null,
  orderId = null,
  orderItemId = null,
  title,
  message,
}) {
  const { rows } = await pool.query(
    `INSERT INTO notifications
       (notification_type, admin_id, shop_owner_id, customer_id, order_id, order_item_id, title, message)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [notificationType, adminId, shopOwnerId, customerId, orderId, orderItemId, title, message]
  );
  return rows[0];
}

async function getActiveAdminIds() {
  const { rows } = await pool.query(`SELECT admin_id FROM admins WHERE is_active = true`);
  return rows.map((r) => r.admin_id);
}

async function getShopOwnerIdByShopId(shopId) {
  const { rows } = await pool.query(
    `SELECT shop_owner_id FROM shop_owners WHERE shop_id = $1`,
    [shopId]
  );
  return rows[0]?.shop_owner_id || null;
}

async function findByRecipient({ column, recipientId, isRead, limit = 20, offset = 0 }) {
  assertValidColumn(column);
  const params = [recipientId];
  let filter = '';
  if (isRead !== undefined) {
    params.push(isRead);
    filter = `AND is_read = $${params.length}`;
  }
  params.push(limit, offset);
  const { rows } = await pool.query(
    `SELECT *
     FROM notifications
     WHERE ${column} = $1 ${filter}
     ORDER BY created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );
  return rows;
}

async function countUnread({ column, recipientId }) {
  assertValidColumn(column);
  const { rows } = await pool.query(
    `SELECT COUNT(*)::int AS count FROM notifications WHERE ${column} = $1 AND is_read = false`,
    [recipientId]
  );
  return rows[0].count;
}

async function markRead({ column, recipientId, notificationId }) {
  assertValidColumn(column);
  const { rows } = await pool.query(
    `UPDATE notifications
     SET is_read = true
     WHERE notification_id = $1 AND ${column} = $2
     RETURNING *`,
    [notificationId, recipientId]
  );
  return rows[0] || null;
}

async function markAllRead({ column, recipientId }) {
  assertValidColumn(column);
  await pool.query(
    `UPDATE notifications SET is_read = true WHERE ${column} = $1 AND is_read = false`,
    [recipientId]
  );
}

module.exports = {
  createNotification,
  getActiveAdminIds,
  getShopOwnerIdByShopId,
  findByRecipient,
  countUnread,
  markRead,
  markAllRead,
};