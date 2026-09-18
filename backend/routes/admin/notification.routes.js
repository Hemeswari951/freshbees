const express = require('express');
const router = express.Router();

const notificationController = require('../../controllers/admin/notification.controller');
const adminAuth = require('../../middleware/adminAuth'); // TODO: confirm actual path

router.use(adminAuth);

router.get('/', notificationController.listNotifications);
router.get('/unread-count', notificationController.unreadCount);
router.patch('/:notificationId/read', notificationController.markRead);
router.patch('/read-all', notificationController.markAllRead);

module.exports = router;