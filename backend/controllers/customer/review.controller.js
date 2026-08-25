const reviewService = require('../../services/customer/review.service');

// ── review row → JSON ──────────────────────────────────────────────────────
function mapReviewRow(row) {
  const fullName = [row.first_name, row.last_name].filter(Boolean).join(' ');
  return {
    reviewId: row.review_id,
    rating: row.rating,
    reviewText: row.review_text,
    createdAt: row.created_at,
    customerName: fullName || 'Anonymous',
    customerProfileImage: row.profile_image || null,
  };
}

// ── summary row → JSON (with % breakdown for the star bars) ───────────────
function mapSummary(row) {
  const totalReviews = Number(row.total_reviews);
  const counts = {
    5: Number(row.star5),
    4: Number(row.star4),
    3: Number(row.star3),
    2: Number(row.star2),
    1: Number(row.star1),
  };
  const breakdown = {};
  for (const star of [5, 4, 3, 2, 1]) {
    breakdown[star] = {
      count: counts[star],
      percent: totalReviews > 0 ? Math.round((counts[star] / totalReviews) * 100) : 0,
    };
  }
  return { avgRating: Number(row.avg_rating), totalReviews, breakdown };
}

// GET /api/customer/products/:productId/reviews?sort=recent&page=1&limit=10
// Public — no auth needed.
async function getProductReviews(req, res) {
  try {
    const productId = Number(req.params.productId);
    const sort = reviewService.VALID_SORTS.includes(req.query.sort) ? req.query.sort : 'recent';
    const limit = Math.min(Math.max(Number(req.query.limit) || 10, 1), 50);
    const page = Math.max(Number(req.query.page) || 1, 1);
    const offset = (page - 1) * limit;

    const [summaryRow, reviewRows, totalCount] = await Promise.all([
      reviewService.getReviewSummary(productId),
      reviewService.getReviews(productId, { sort, limit, offset }),
      reviewService.countReviews(productId),
    ]);

    res.json({
      success: true,
      data: {
        summary: mapSummary(summaryRow),
        reviews: reviewRows.map(mapReviewRow),
        pagination: {
          page,
          limit,
          totalCount,
          totalPages: Math.ceil(totalCount / limit) || 1,
        },
      },
    });
  } catch (err) {
    console.error('[customer getProductReviews]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch reviews' });
  }
}

// GET /api/customer/products/:productId/reviews/eligibility
// Requires customerAuth — decides "Write a review" vs "Edit your review".
async function getReviewEligibility(req, res) {
  try {
    const productId = Number(req.params.productId);
    const customerId = req.customer.customerId;

    const [isVerifiedPurchase, existing] = await Promise.all([
      reviewService.hasDeliveredPurchase(customerId, productId),
      reviewService.findReviewByCustomer(customerId, productId),
    ]);

    res.json({
      success: true,
      data: {
        isVerifiedPurchase,
        alreadyReviewed: !!existing,
        existingReview: existing
          ? {
              reviewId: existing.review_id,
              rating: existing.rating,
              reviewText: existing.review_text,
              createdAt: existing.created_at,
            }
          : null,
        canSubmit: isVerifiedPurchase && !existing,
      },
    });
  } catch (err) {
    console.error('[customer getReviewEligibility]', err);
    res.status(500).json({ success: false, message: 'Failed to check review eligibility' });
  }
}

// POST /api/customer/products/:productId/reviews
// body: { rating, reviewText }. Requires customerAuth + Delivered order + no
// existing review for this product.
async function submitReview(req, res) {
  try {
    const productId = Number(req.params.productId);
    const customerId = req.customer.customerId;
    const { rating, reviewText } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ success: false, message: 'Rating must be between 1 and 5.' });
    }

    // Verified-purchase + duplicate-review checks now live in the service.
    const created = await reviewService.createReview(customerId, productId, { rating, reviewText });
    res.status(201).json({
      success: true,
      data: {
        reviewId: created.review_id,
        rating: created.rating,
        reviewText: created.review_text,
        createdAt: created.created_at,
      },
    });
  } catch (err) {
    if (err.statusCode) {
      return res.status(err.statusCode).json({ success: false, message: err.message });
    }
    console.error('[customer submitReview]', err);
    res.status(500).json({ success: false, message: 'Failed to submit review' });
  }
}

// PUT /api/customer/products/:productId/reviews/:reviewId
// body: { rating, reviewText }. Requires customerAuth + must own the review.
async function editReview(req, res) {
  try {
    const { reviewId } = req.params;
    const customerId = req.customer.customerId;
    const { rating, reviewText } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ success: false, message: 'Rating must be between 1 and 5.' });
    }

    const updated = await reviewService.updateReview(reviewId, customerId, { rating, reviewText });

    res.json({
      success: true,
      data: {
        reviewId: updated.review_id,
        rating: updated.rating,
        reviewText: updated.review_text,
        createdAt: updated.created_at,
      },
    });
  } catch (err) {
    if (err.statusCode) {
      return res.status(err.statusCode).json({ success: false, message: err.message });
    }
    console.error('[customer editReview]', err);
    res.status(500).json({ success: false, message: 'Failed to update review' });
  }
}

module.exports = { getProductReviews, getReviewEligibility, submitReview, editReview };