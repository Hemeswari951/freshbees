const express = require('express');
const router  = express.Router();
const adminAuth = require('../../middleware/adminauth');
const ctrl    = require('../../controllers/admin/dashboard.controller');

// All admin dashboard routes require a valid admin JWT
router.use(adminAuth);

// Admin dashboard routes
router.get('/', ctrl.getDashboardData);

// Create a new admin user
router.post('/create-admin', ctrl.createAdmin);
module.exports = router;