const express = require('express');
const router = express.Router();

const notificationController = require('../../controllers/customer/notification.controller');
const customerAuth = require('../../middleware/customerAuth');

router.use(customerAuth);

router.get('/', notificationController.listNotifications);
router.get('/unread-count', notificationController.unreadCount);
router.patch('/:notificationId/read', notificationController.markRead);
router.patch('/read-all', notificationController.markAllRead);

module.exports = router;