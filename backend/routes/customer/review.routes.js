const express = require('express');
const router = express.Router({ mergeParams: true }); // so :productId (from the app.js mount path) is visible here

const reviewController = require('../../controllers/customer/review.controller');
// TODO: confirm this path matches where customerAuth.js actually lives in your project.
const customerAuth = require('../../middleware/customerAuth');

// GET /api/customer/products/:productId/reviews?sort=recent&page=1&limit=10
router.get('/', reviewController.getProductReviews);

// GET /api/customer/products/:productId/reviews/eligibility
router.get('/eligibility', customerAuth, reviewController.getReviewEligibility);

// POST /api/customer/products/:productId/reviews
router.post('/', customerAuth, reviewController.submitReview);

// PUT /api/customer/products/:productId/reviews/:reviewId
router.put('/:reviewId', customerAuth, reviewController.editReview);

module.exports = router;