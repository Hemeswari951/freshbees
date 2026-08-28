const express = require("express");

const router = express.Router();

const tryonProfileController =
    require("../../controllers/customer/tryonProfile.controller");

const customerAuth =
    require("../../middleware/customerAuth");

const {
  upload,
  handleUploadError,
} = require("../../middleware/upload");

// All Try-On Profile APIs require a logged-in customer.
router.use(customerAuth);


// GET /api/customer/tryon-profiles
// Get all profiles of the logged-in customer
router.get(
    "/",
    tryonProfileController.getProfiles
);


// GET /api/customer/tryon-profiles/:id
// Get one profile
router.get(
    "/:id",
    tryonProfileController.getProfile
);


// POST /api/customer/tryon-profiles
// Create a new profile
router.post(
    "/",
    tryonProfileController.createProfile
);


// PUT /api/customer/tryon-profiles/:id
// Update a profile
router.put(
    "/:id",
    tryonProfileController.updateProfile
);


// DELETE /api/customer/tryon-profiles/:id
// Delete a profile
router.delete(
    "/:id",
    tryonProfileController.deleteProfile
);


router.post(
  "/:profileId/photo",
  upload.single("photo"),
  tryonProfileController.uploadProfilePhoto,
  handleUploadError
);

module.exports = router;