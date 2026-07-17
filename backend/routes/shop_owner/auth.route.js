const express = require("express");
const router = express.Router();

const shopOwnerAuthController = require("../../controllers/shop_owner/auth.controller");
const shopOwnerAuth = require("../../middleware/shopownerauth");

router.post("/login", shopOwnerAuthController.login);
router.post("/logout", shopOwnerAuth, shopOwnerAuthController.logout);

router.post('/forgot-password', shopOwnerAuthController.forgotPassword);
router.post('/verify-otp', shopOwnerAuthController.verifyOtp);
router.post('/reset-password', shopOwnerAuthController.resetPassword);

module.exports = router;