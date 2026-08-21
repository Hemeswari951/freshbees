const reviewModel = require('../../models/customer/review.model');

const VALID_SORTS = ['recent', 'highest', 'lowest'];

// ── just pass-throughs to the model, with sort validated here ─────────────
async function getReviewSummary(productId) {
  return reviewModel.getReviewSummary(productId);
}

async function getReviews(productId, { sort = 'recent', limit = 10, offset = 0 } = {}) {
  const safeSort = VALID_SORTS.includes(sort) ? sort : 'recent';
  return reviewModel.getReviews(productId, { sort: safeSort, limit, offset });
}

async function countReviews(productId) {
  return reviewModel.countReviews(productId);
}

async function hasDeliveredPurchase(customerId, productId) {
  return reviewModel.hasDeliveredPurchase(customerId, productId);
}

async function findReviewByCustomer(customerId, productId) {
  return reviewModel.findReviewByCustomer(customerId, productId);
}

// ── business rules live here, not in the controller or the model ──────────

async function createReview(customerId, productId, { rating, reviewText }) {
  const isVerifiedPurchase = await reviewModel.hasDeliveredPurchase(customerId, productId);
  if (!isVerifiedPurchase) {
    const err = new Error('Only customers with a delivered order can review this product.');
    err.statusCode = 403;
    throw err;
  }

  const existing = await reviewModel.findReviewByCustomer(customerId, productId);
  if (existing) {
    const err = new Error('You have already reviewed this product. Edit your existing review instead.');
    err.statusCode = 409;
    throw err;
  }

  return reviewModel.createReview(customerId, productId, { rating, reviewText });
}

async function updateReview(reviewId, customerId, { rating, reviewText }) {
  const updated = await reviewModel.updateReview(reviewId, customerId, { rating, reviewText });
  if (!updated) {
    const err = new Error('Review not found, or you do not own this review.');
    err.statusCode = 404;
    throw err;
  }
  return updated;
}

module.exports = {
  VALID_SORTS,
  getReviewSummary,
  getReviews,
  countReviews,
  hasDeliveredPurchase,
  findReviewByCustomer,
  createReview,
  updateReview,
};