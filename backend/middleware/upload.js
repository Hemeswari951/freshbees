const multer = require("multer");
const path = require("path");

// Memory Storage
const storage = multer.memoryStorage();

// Product image field patterns
const FIELD_NAME_RE = /^color_(\d+)_(front|back|side|zoom)$/;
const SPIN_FIELD_NAME_RE = /^color_(\d+)_360_(\d+)$/;

// Image validation
function imageFileFilter(req, file, cb) {
  const allowed = [".jpg", ".jpeg", ".png", ".webp"];

  const ext = path.extname(file.originalname).toLowerCase();

  if (!allowed.includes(ext)) {
    return cb(
      new Error(
        "Only image files are allowed (jpg, jpeg, png, webp)"
      )
    );
  }

  cb(null, true);
}

// Common upload middleware
const upload = multer({
  storage,
  fileFilter: imageFileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024,
    files: 250,
  },
});

// Product image field validator
function validateProductImageFields(req, res, next) {

  if (!req.files || req.files.length === 0) {
    return next();
  }

  for (const file of req.files) {

    const valid =
      FIELD_NAME_RE.test(file.fieldname) ||
      SPIN_FIELD_NAME_RE.test(file.fieldname);

    if (!valid) {
      return res.status(400).json({
        success: false,
        message: `Unexpected image field "${file.fieldname}"`,
      });
    }
  }

  next();
}

// Upload error handler
function handleUploadError(err, req, res, next) {

  if (err instanceof multer.MulterError) {

    if (err.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        success: false,
        message: "File too large. Maximum size is 5MB.",
      });
    }

    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }

  if (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }

  next();
}

module.exports = {
  upload,
  validateProductImageFields,
  handleUploadError,
  FIELD_NAME_RE,
  SPIN_FIELD_NAME_RE,
};