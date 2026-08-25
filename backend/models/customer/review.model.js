const pool = require('../../config/db');

// ── Overall rating summary (avg + total + star-wise breakdown) ────────────
async function getReviewSummary(productId) {
  const { rows } = await pool.query(
    `
    SELECT
      COALESCE(AVG(rating), 0)::NUMERIC(3,2) AS avg_rating,
      COUNT(*)                               AS total_reviews,
      COUNT(*) FILTER (WHERE rating = 5)     AS star5,
      COUNT(*) FILTER (WHERE rating = 4)     AS star4,
      COUNT(*) FILTER (WHERE rating = 3)     AS star3,
      COUNT(*) FILTER (WHERE rating = 2)     AS star2,
      COUNT(*) FILTER (WHERE rating = 1)     AS star1
    FROM reviews
    WHERE product_id = $1
    `,
    [productId]
  );
  return rows[0];
}

// ── Paginated review list, joined with the reviewer's display info ────────
async function getReviews(productId, { sort = 'recent', limit = 10, offset = 0 } = {}) {
  const orderClause =
    sort === 'highest'
      ? 'r.rating DESC, r.created_at DESC'
      : sort === 'lowest'
      ? 'r.rating ASC, r.created_at DESC'
      : 'r.created_at DESC'; // 'recent' (default)

  const { rows } = await pool.query(
    `
    SELECT
      r.review_id,
      r.rating,
      r.review_text,
      r.created_at,
      c.customer_id,
      c.first_name,
      c.last_name,
      c.profile_image
    FROM reviews r
    JOIN customers c ON c.customer_id = r.customer_id
    WHERE r.product_id = $1
    ORDER BY ${orderClause}
    LIMIT $2 OFFSET $3
    `,
    [productId, limit, offset]
  );
  return rows;
}

async function countReviews(productId) {
  const { rows } = await pool.query(
    'SELECT COUNT(*)::int AS count FROM reviews WHERE product_id = $1',
    [productId]
  );
  return rows[0].count;
}

// ── "Verified Purchase" check — did this customer get this product delivered? ──
// TODO: confirm 'Delivered' is the exact item_status string your order flow
// sets (case-sensitive) — adjust if your order system uses something else.
async function hasDeliveredPurchase(customerId, productId) {
  const { rows } = await pool.query(
    `
    SELECT 1
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.customer_id = $1
      AND oi.product_id = $2
      AND oi.item_status = 'Delivered'
    LIMIT 1
    `,
    [customerId, productId]
  );
  return rows.length > 0;
}

async function findReviewByCustomer(customerId, productId) {
  const { rows } = await pool.query(
    `SELECT review_id, rating, review_text, created_at
     FROM reviews
     WHERE customer_id = $1 AND product_id = $2`,
    [customerId, productId]
  );
  return rows[0] || null;
}

async function createReview(customerId, productId, { rating, reviewText }) {
  const { rows } = await pool.query(
    `INSERT INTO reviews (customer_id, product_id, rating, review_text)
     VALUES ($1, $2, $3, $4)
     RETURNING review_id, rating, review_text, created_at`,
    [customerId, productId, rating, reviewText]
  );
  return rows[0];
}

async function updateReview(reviewId, customerId, { rating, reviewText }) {
  const { rows } = await pool.query(
    `UPDATE reviews
     SET rating = $3, review_text = $4
     WHERE review_id = $1 AND customer_id = $2
     RETURNING review_id, rating, review_text, created_at`,
    [reviewId, customerId, rating, reviewText]
  );
  return rows[0] || null;
}

module.exports = {
  getReviewSummary,
  getReviews,
  countReviews,
  hasDeliveredPurchase,
  findReviewByCustomer,
  createReview,
  updateReview,
};