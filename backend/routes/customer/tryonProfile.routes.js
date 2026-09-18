const express = require("express");

const router = express.Router();

const tryonProfileController =
  require("../../controllers/customer/tryonProfile.controller");

const tryOnProfileStyleController =
  require("../../controllers/customer/tryon_profile_style.controller");

const customerAuth =
  require("../../middleware/customerauth");

const {
  upload,
  handleUploadError,
} = require("../../middleware/upload");


// =====================================================
// AUTHENTICATION
// =====================================================

// All Try-On Profile APIs require a logged-in customer.
router.use(customerAuth);


// =====================================================
// GET ALL PROFILES
// GET /api/customer/tryon-profiles
// =====================================================

router.get(
  "/",
  tryonProfileController.getProfiles
);

// =====================================================
// GET MAIN USER TRY-ON PROFILE
// GET /api/customer/tryon-profiles/main
// =====================================================

router.get(
  "/main",
  tryonProfileController.getMainProfile
);

// =====================================================
// GET PROFILE STYLE
// GET /api/customer/tryon-profiles/:id/style
// =====================================================

router.get(
  "/:id/style",
  tryOnProfileStyleController.getStyle
);


// =====================================================
// UPDATE PROFILE STYLE
// PUT /api/customer/tryon-profiles/:id/style
// =====================================================

router.put(
  "/:id/style",
  tryOnProfileStyleController.saveStyle
);


// =====================================================
// GET ONE PROFILE
// GET /api/customer/tryon-profiles/:id
// =====================================================

router.get(
  "/:id",
  tryonProfileController.getProfile
);



// =====================================================
// CREATE PROFILE
// POST /api/customer/tryon-profiles
// =====================================================

router.post(
  "/",
  tryonProfileController.createProfile
);


// =====================================================
// UPDATE PROFILE
// PUT /api/customer/tryon-profiles/:id
// =====================================================

router.put(
  "/:id",
  tryonProfileController.updateProfile
);


// =====================================================
// DELETE PROFILE
// DELETE /api/customer/tryon-profiles/:id
// =====================================================

router.delete(
  "/:id",
  tryonProfileController.deleteProfile
);


// =====================================================
// UPLOAD PROFILE PHOTO
// POST /api/customer/tryon-profiles/:profileId/photo
// =====================================================

router.post(
  "/:profileId/photo",
  upload.single("photo"),
  tryonProfileController.uploadProfilePhoto,
  handleUploadError
);


module.exports = router;