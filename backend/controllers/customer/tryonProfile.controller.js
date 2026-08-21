const tryonProfileModel = require("../../models/customer/tryonProfileModel");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// =====================================================
// TRY-ON PHOTO UPLOAD CONFIGURATION
// =====================================================

const uploadDir = path.join(
  __dirname,
  "../../uploads/tryon"
);

// Create upload directory if it doesn't exist
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, {
    recursive: true,
  });
}

// =====================================================
// MULTER STORAGE
// =====================================================

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },

  filename: (req, file, cb) => {
    const profileId = req.params.profileId;

    const extension = path.extname(
      file.originalname
    );

    const filename =
      `profile_${profileId}_${Date.now()}${extension}`;

    cb(null, filename);
  },
});

// =====================================================
// MULTER UPLOAD
// =====================================================

const upload = multer({
  storage,

  fileFilter: (req, file, cb) => {
    const allowedTypes = [
      "image/jpeg",
      "image/jpg",
      "image/png",
      "image/webp",
    ];

    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new Error(
          "Only JPG, JPEG, PNG and WEBP images are allowed"
        )
      );
    }
  },

  limits: {
    fileSize: 10 * 1024 * 1024,
  },
});

// =====================================================
// UPLOAD TRY-ON PROFILE PHOTO
// POST /api/customer/tryon-profiles/:profileId/photo
// =====================================================

exports.uploadProfilePhoto = async (req, res) => {
  try {
    const customerId = req.customer.customerId;
    const profileId = Number(req.params.profileId);

    // -----------------------------------------------
    // Validate profile ID
    // -----------------------------------------------

    if (!profileId) {
      return res.status(400).json({
        success: false,
        message: "Invalid profile ID",
      });
    }

    // -----------------------------------------------
    // Find profile belonging to logged-in customer
    // -----------------------------------------------

    const profile =
      await tryonProfileModel.getById(
        profileId,
        customerId
      );

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: "Try-on profile not found",
      });
    }

    // -----------------------------------------------
    // Check uploaded file
    // -----------------------------------------------

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Photo is required",
      });
    }

    // -----------------------------------------------
    // Check file buffer
    // -----------------------------------------------

    if (!req.file.buffer) {
      return res.status(400).json({
        success: false,
        message: "Uploaded photo data is missing",
      });
    }

    // -----------------------------------------------
    // Create upload directory
    // -----------------------------------------------

    const uploadDir = path.join(
      __dirname,
      "../../uploads/tryon"
    );

    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, {
        recursive: true,
      });
    }

    // -----------------------------------------------
    // Create filename
    // -----------------------------------------------

    const extension =
      path.extname(
        req.file.originalname
      ).toLowerCase();

    const filename =
      `profile_${profileId}_${Date.now()}${extension}`;

    // -----------------------------------------------
    // Full file path
    // -----------------------------------------------

    const filePath =
      path.join(
        uploadDir,
        filename
      );

    // -----------------------------------------------
    // Save buffer to disk
    // -----------------------------------------------

    fs.writeFileSync(
      filePath,
      req.file.buffer
    );

    console.log(
      "TRY-ON PHOTO SAVED:",
      filePath
    );

    // -----------------------------------------------
    // Public URL
    // -----------------------------------------------

    const photoUrl =
      `/uploads/tryon/${filename}`;

    console.log(
      "TRY-ON PHOTO URL:",
      photoUrl
    );

    // -----------------------------------------------
    // Update PostgreSQL
    // -----------------------------------------------

    const updatedProfile =
      await tryonProfileModel.update(
        profileId,
        customerId,
        {
          photoUrl: photoUrl,
        }
      );

    if (!updatedProfile) {
      return res.status(404).json({
        success: false,
        message: "Try-on profile not found",
      });
    }

    // -----------------------------------------------
    // Success
    // -----------------------------------------------

    return res.status(200).json({
      success: true,
      message: "Photo uploaded successfully",
      data: updatedProfile,
    });

  } catch (error) {
    console.error(
      "[uploadProfilePhoto]",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Failed to upload profile photo",
      error: error.message,
    });
  }
};

// =====================================================
// GET ALL TRY-ON PROFILES
// GET /api/customer/tryon-profiles
// =====================================================

exports.getProfiles = async (req, res) => {
  try {
    const customerId =
      req.customer.customerId;

    const profiles =
      await tryonProfileModel.getByCustomerId(
        customerId
      );

    return res.json({
      success: true,
      data: profiles,
    });

  } catch (err) {
    console.error(
      "Get Try-On Profiles Error:",
      err
    );

    return res.status(500).json({
      success: false,
      message: "Failed to fetch try-on profiles",
      error: err.message,
    });
  }
};

// =====================================================
// GET ONE TRY-ON PROFILE
// GET /api/customer/tryon-profiles/:id
// =====================================================

exports.getProfile = async (req, res) => {
  try {
    const customerId =
      req.customer.customerId;

    const profileId =
      Number(req.params.id);

    // -----------------------------------------------
    // Validate profile ID
    // -----------------------------------------------

    if (!profileId) {
      return res.status(400).json({
        success: false,
        message: "Invalid profile ID",
      });
    }

    // -----------------------------------------------
    // Get profile
    // -----------------------------------------------

    const profile =
      await tryonProfileModel.getById(
        profileId,
        customerId
      );

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: "Try-on profile not found",
      });
    }

    return res.json({
      success: true,
      data: profile,
    });

  } catch (err) {
    console.error(
      "Get Try-On Profile Error:",
      err
    );

    return res.status(500).json({
      success: false,
      message: "Failed to fetch try-on profile",
      error: err.message,
    });
  }
};

// =====================================================
// CREATE TRY-ON PROFILE
// POST /api/customer/tryon-profiles
// =====================================================

exports.createProfile = async (req, res) => {
  try {
    const customerId =
      req.customer.customerId;

    const {
      profileName,
      relationship,
      gender,
      age,
      size,
      height,
      weight,
      photoUrl,
      isDefault,
    } = req.body;

    // -----------------------------------------------
    // Required fields
    // -----------------------------------------------

    if (!profileName || !relationship) {
      return res.status(400).json({
        success: false,
        message:
          "Profile name and relationship are required",
      });
    }

    // -----------------------------------------------
    // Create profile
    // -----------------------------------------------

    const profile =
      await tryonProfileModel.create({
        customerId,
        profileName,
        relationship,
        gender,
        age,
        size,
        height,
        weight,
        photoUrl,
        isDefault: isDefault === true,
      });

    return res.status(201).json({
      success: true,
      message:
        "Try-on profile created successfully",
      data: profile,
    });

  } catch (err) {
    console.error(
      "Create Try-On Profile Error:",
      err
    );

    return res.status(500).json({
      success: false,
      message:
        "Failed to create try-on profile",
      error: err.message,
    });
  }
};

// =====================================================
// UPDATE TRY-ON PROFILE
// PUT /api/customer/tryon-profiles/:id
// =====================================================

exports.updateProfile = async (req, res) => {
  try {
    const customerId =
      req.customer.customerId;

    const profileId =
      Number(req.params.id);

    // -----------------------------------------------
    // Validate profile ID
    // -----------------------------------------------

    if (!profileId) {
      return res.status(400).json({
        success: false,
        message: "Invalid profile ID",
      });
    }

    const {
      profileName,
      relationship,
      gender,
      age,
      size,
      height,
      weight,
      photoUrl,
    } = req.body;

    // -----------------------------------------------
    // Update profile
    // -----------------------------------------------

    const updatedProfile =
      await tryonProfileModel.update(
        profileId,
        customerId,
        {
          profileName,
          relationship,
          gender,
          age,
          size,
          height,
          weight,
          photoUrl,
        }
      );

    // -----------------------------------------------
    // Profile not found
    // -----------------------------------------------

    if (!updatedProfile) {
      return res.status(404).json({
        success: false,
        message: "Try-on profile not found",
      });
    }

    return res.json({
      success: true,
      message:
        "Try-on profile updated successfully",
      data: updatedProfile,
    });

  } catch (err) {
    console.error(
      "Update Try-On Profile Error:",
      err
    );

    return res.status(500).json({
      success: false,
      message:
        "Failed to update try-on profile",
      error: err.message,
    });
  }
};

// =====================================================
// DELETE TRY-ON PROFILE
// DELETE /api/customer/tryon-profiles/:id
// =====================================================

exports.deleteProfile = async (req, res) => {
  try {
    const customerId =
      req.customer.customerId;

    const profileId =
      Number(req.params.id);

    // -----------------------------------------------
    // Validate profile ID
    // -----------------------------------------------

    if (!profileId) {
      return res.status(400).json({
        success: false,
        message: "Invalid profile ID",
      });
    }

    // -----------------------------------------------
    // Delete profile
    // -----------------------------------------------

    const deletedProfile =
      await tryonProfileModel.delete(
        profileId,
        customerId
      );

    if (!deletedProfile) {
      return res.status(404).json({
        success: false,
        message: "Try-on profile not found",
      });
    }

    return res.json({
      success: true,
      message:
        "Try-on profile deleted successfully",
    });

  } catch (err) {
    console.error(
      "Delete Try-On Profile Error:",
      err
    );

    return res.status(500).json({
      success: false,
      message:
        "Failed to delete try-on profile",
      error: err.message,
    });
  }
};

// =====================================================
// EXPORT MULTER UPLOAD
// =====================================================

exports.upload = upload;