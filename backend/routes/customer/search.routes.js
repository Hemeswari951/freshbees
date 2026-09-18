const express = require('express');
const router = express.Router();

const searchController = require('../../controllers/customer/search.controller');
const { upload, handleUploadError } = require('../../middleware/upload');

// GET /api/customer/search/suggestions?q=ts
router.get('/suggestions', searchController.getSearchSuggestions);

// POST /api/customer/search/image  (multipart/form-data, field: "image")
// Camera-icon visual search — Take Photo / Choose from Gallery both land
// here with the picked/captured photo.
router.post(
  '/image',
  upload.single('image'),
  handleUploadError,
  searchController.imageSearch
);

module.exports = router;