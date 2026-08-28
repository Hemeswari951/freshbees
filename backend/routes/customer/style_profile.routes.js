const express = require("express");

const router = express.Router();

const styleProfileController = require("../../controllers/customer/style_profile.controller");

const customerAuth = require("../../middleware/customerAuth");

// Every style-profile route requires a logged-in customer.
router.use(customerAuth);

// GET /api/customer/style-profile
// Get the logged-in customer's style profile.
router.get(
    "/",
    styleProfileController.getStyleProfile
);

// PUT /api/customer/style-profile
// Create or update the logged-in customer's style profile.
router.put(
    "/",
    styleProfileController.saveStyleProfile
);

module.exports = router;