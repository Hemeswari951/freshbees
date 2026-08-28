const express = require('express');
const router = express.Router();

const searchController = require('../../controllers/customer/search.controller');

// GET /api/customer/search/suggestions?q=ts
router.get('/suggestions', searchController.getSearchSuggestions);

module.exports = router;