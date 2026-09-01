// backend/services/customer/wishlist.service.js
const pool = require('../../config/db');

// discount_percent is never stored — same derivation used everywhere else
// on the customer side (see services/customer/product.service.js).
const DISCOUNT_SQL = `
  CASE
    WHEN p.mrp IS NULL OR p.mrp <= 0 OR p.mrp <= p.price THEN 0
    ELSE ROUND(((p.mrp - p.price) / p.mrp) * 100)::INT
  END
`;

// ── Add a product to the customer's wishlist ──────────────────────────────
// Manual existence check instead of relying on an ON CONFLICT upsert, so
// this keeps working even if the (customer_id, product_id) unique
// constraint is ever missing, renamed, or dropped by a future migration.
// Adding something that's already wishlisted is a harmless no-op.
async function addToWishlist(customerId, productId) {
  const existing = await pool.query(
    `SELECT wishlist_id FROM wishlist
     WHERE customer_id = $1 AND product_id = $2`,
    [customerId, productId]
  );

  if (existing.rows[0]) {
    return existing.rows[0]; // already wishlisted — nothing to do
  }

  const { rows } = await pool.query(
    `INSERT INTO wishlist (customer_id, product_id)
     VALUES ($1, $2)
     RETURNING wishlist_id`,
    [customerId, productId]
  );
  return rows[0] || null;
}

// ── Remove a product from the customer's wishlist ─────────────────────────
async function removeFromWishlist(customerId, productId) {
  const { rows } = await pool.query(
    `DELETE FROM wishlist
     WHERE customer_id = $1 AND product_id = $2
     RETURNING wishlist_id`,
    [customerId, productId]
  );
  return rows[0] || null;
}

// ── Every wishlisted product for this customer ─────────────────────────────
// Same active-product / unblocked-shop rule as the rest of the customer
// catalog (see findAllPublicProducts) — if the owner deactivates a product
// or the admin blocks its shop, it simply stops appearing here. The
// wishlist row itself is left untouched, so it reappears automatically the
// moment the product/shop is reactivated.
//
// Ratings: there is no `rating` column on `products` — it has to be
// derived from the `reviews` table (one row per customer review, 1-5
// stars). The `rv` LATERAL/subquery below computes the average rating and
// review count per product, same idea as the commented-out
// `product_ratings` view in schema.sql, just inlined here so it stays in
// one query instead of needing a real view + a join to it.
async function getWishlistProducts(customerId) {
  const { rows } = await pool.query(
    `
    SELECT
      p.product_id,
      p.product_name,
      p.sub_category,
      p.description,
      p.mrp,
      p.price,
      ${DISCOUNT_SQL} AS discount_percent,
      p.shop_id,
      s.shop_name,
      p.category_id,
      cat.category_name,
      b.brand_name,
      COALESCE(img.image_url, NULL) AS thumbnail,
      COALESCE(v.total_stock, 0) AS total_stock,
      COALESCE(rv.avg_rating, 0)::NUMERIC(3,2) AS rating,
      COALESCE(rv.review_count, 0) AS review_count,
      w.added_at
    FROM wishlist w
    JOIN products p ON p.product_id = w.product_id
    JOIN shops s ON s.shop_id = p.shop_id
    LEFT JOIN categories cat ON cat.category_id = p.category_id
    LEFT JOIN brands b ON b.brand_id = p.brand_id
    LEFT JOIN LATERAL (
      SELECT pi.image_url
      FROM product_images pi
      JOIN product_colors pc ON pc.product_color_id = pi.product_color_id
      WHERE pc.product_id = p.product_id
      ORDER BY pc.created_at ASC,
               CASE pi.image_type WHEN 'front' THEN 0 ELSE 1 END,
               pi.display_order ASC
      LIMIT 1
    ) img ON true
    LEFT JOIN (
      SELECT product_id, SUM(stock_quantity) AS total_stock
      FROM product_variants
      GROUP BY product_id
    ) v ON v.product_id = p.product_id
    LEFT JOIN (
      SELECT product_id, AVG(rating) AS avg_rating, COUNT(review_id) AS review_count
      FROM reviews
      GROUP BY product_id
    ) rv ON rv.product_id = p.product_id
    WHERE w.customer_id = $1
      AND p.is_active = true
      AND s.is_blocked = false
    ORDER BY w.added_at DESC
    `,
    [customerId]
  );
  return rows;
}

module.exports = {
  addToWishlist,
  removeFromWishlist,
  getWishlistProducts,
};