const express = require('express');
const router = express.Router();

const notificationController = require('../../controllers/shop_owner/notification.controller');
const shopOwnerAuth = require('../../middleware/shopownerauth'); // TODO: confirm actual path

router.use(shopOwnerAuth);

router.get('/', notificationController.listNotifications);
router.get('/unread-count', notificationController.unreadCount);
router.patch('/:notificationId/read', notificationController.markRead);
router.patch('/read-all', notificationController.markAllRead);

module.exports = router;