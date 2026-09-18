const express = require("express");

const router = express.Router();

const profileController =
    require("../../controllers/customer/profile.controller");

const customerAuth =
    require("../../middleware/customerauth");

// All profile routes require logged-in customer.
router.use(customerAuth);

// GET /api/customer/profile
router.get(
    "/",
    profileController.getProfile
);

router.put(
    "/",
    profileController.updateProfile
);

module.exports = router;