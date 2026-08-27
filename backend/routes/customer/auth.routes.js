const express = require("express");
const router = express.Router();
 
const authController = require("../../controllers/customer/auth.controller");
const customerAuth = require('../../middleware/customerauth');
 
// OTP
router.post("/send-otp", authController.sendOtp);
router.post("/verify-otp", authController.verifyOtp);
 
// Register
router.post("/register", authController.register);
 
// Password Login
router.post("/login", authController.login);
 
// Forgot Password
router.post("/forgot-password", authController.forgotPassword);
 
// Reset Password
router.post("/reset-password", authController.resetPassword);

// Refresh Access Token

router.post(
  "/refresh-token",
  authController.refreshAccessToken
);
 
// Logout
router.post("/logout", customerAuth, authController.logout);



module.exports = router;