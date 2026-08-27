const express = require('express');
const router = express.Router();

const settingsController = require('../../controllers/customer/settings.controller');

// GET /api/customer/settings — public, no auth (About Us / footer / contact)
router.get('/', settingsController.getSettings);

module.exports = router;