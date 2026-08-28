const express = require("express");
const router = express.Router();

const authController = require("../../controllers/admin/auth.controller");
const adminAuth = require("../../middleware/adminauth");

router.post("/login", authController.login);

router.post("/logout", adminAuth, authController.logout);

module.exports = router;