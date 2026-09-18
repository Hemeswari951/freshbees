const express = require("express");

const router = express.Router();

const customerAuth = require("../../middleware/customerauth");
const virtualTryonController = require("../../controllers/customer/virtualTryon.controller");
const {
  upload,
  handleUploadError,
} = require("../../middleware/upload");

console.log("[virtualTryon.routes] Module loaded successfully");
console.log("[virtualTryon.routes] virtualTryonController:", typeof virtualTryonController);
console.log("[virtualTryon.routes] generateTryOn function:", typeof virtualTryonController.generateTryOn);

router.use(customerAuth);

// Test endpoint to verify route is working
router.post("/test", (req, res) => {
  res.json({ success: true, message: "Virtual Try-On route is working" });
});

router.post(
  "/generate",
  upload.single("customerPhoto"),
  virtualTryonController.generateTryOn
);

module.exports = router;
