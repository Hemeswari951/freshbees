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
// backend/services/customer/wishlist.service.js
async function addToWishlist(customerId, productId, productColorId = null) {
  // Check if THIS SPECIFIC COLOR is already wishlisted
  const existing = await pool.query(
    `SELECT wishlist_id FROM wishlist
     WHERE customer_id = $1 
       AND product_id = $2
       AND (product_color_id = $3 OR ($3::int IS NULL AND product_color_id IS NULL))`,
    [customerId, productId, productColorId]
  );

  if (existing.rows[0]) {
    return existing.rows[0]; // already wishlisted this specific color
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO wishlist (customer_id, product_id, product_color_id)
       VALUES ($1, $2, $3)
       RETURNING wishlist_id`,
      [customerId, productId, productColorId]
    );
    return rows[0] || null;
  } catch (err) {
    if (err.code === '23505') {
      // It's a unique violation. Check if it was THIS exact color that caused it.
      const check = await pool.query(
        `SELECT wishlist_id FROM wishlist
         WHERE customer_id = $1 
           AND product_id = $2
           AND (product_color_id = $3 OR ($3::int IS NULL AND product_color_id IS NULL))`,
        [customerId, productId, productColorId]
      );

      if (check.rows[0]) return check.rows[0];

      // If it reaches here, the database STILL has the old constraint blocking multiple colors!
      throw new Error('Database constraint blocking multiple colors. Please run the SQL migration.');
    }
    throw err;
  }
}

async function removeFromWishlist(customerId, productId, productColorId = null) {
  // Only remove THIS SPECIFIC COLOR
  const { rows } = await pool.query(
    `DELETE FROM wishlist
     WHERE customer_id = $1 
       AND product_id = $2
       AND (product_color_id = $3 OR ($3::int IS NULL AND product_color_id IS NULL))
     RETURNING wishlist_id`,
    [customerId, productId, productColorId]
  );
  return rows[0] || null;
}

// ── Every product the customer has wishlisted ──────────────────────────────
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
      w.product_color_id AS product_color_id, -- <-- ADD THIS LINE
      COALESCE(v.total_stock, 0) AS total_stock,
      v.sizes,
      c.colors,
      COALESCE(vr.variants, '[]'::json) AS variants,
      COALESCE(rv.avg_rating, 0)::NUMERIC(3,2) AS rating,
      COALESCE(rv.review_count, 0) AS review_count,
      w.added_at
    FROM wishlist w
    JOIN products p ON p.product_id = w.product_id
    JOIN shops s ON s.shop_id = p.shop_id
    LEFT JOIN categories cat ON cat.category_id = p.category_id
    LEFT JOIN brands b ON b.brand_id = p.brand_id

    -- ---------------------------------------------------------------------
    -- THUMBNAIL — locked to the wishlisted color (w.product_color_id) when
    -- present, otherwise the original "first uploaded color" fallback.
    -- ---------------------------------------------------------------------
    LEFT JOIN LATERAL (
      SELECT pi.image_url
      FROM product_images pi
      JOIN product_colors pc ON pc.product_color_id = pi.product_color_id
      WHERE pc.product_id = p.product_id
      ORDER BY
        CASE
          WHEN w.product_color_id IS NOT NULL
           AND pc.product_color_id = w.product_color_id
          THEN 0 ELSE 1
        END,
        pc.created_at ASC,
        CASE pi.image_type WHEN 'front' THEN 0 ELSE 1 END,
        pi.display_order ASC
      LIMIT 1
    ) img ON true

    -- ---------------------------------------------------------------------
    -- STOCK + SIZES — only the wishlisted color's variants when a color
    -- was recorded; all variants (old behaviour) when it wasn't.
    -- ---------------------------------------------------------------------
    LEFT JOIN LATERAL (
      SELECT
        SUM(pv.stock_quantity) AS total_stock,
        ARRAY_AGG(DISTINCT pv.size) AS sizes
      FROM product_variants pv
      WHERE pv.product_id = p.product_id
        AND (w.product_color_id IS NULL OR pv.product_color_id = w.product_color_id)
    ) v ON true

    -- ---------------------------------------------------------------------
    -- COLORS — just the one wishlisted color when present, else every
    -- color the product has (legacy rows with no product_color_id).
    -- ---------------------------------------------------------------------
    LEFT JOIN LATERAL (
      SELECT ARRAY_AGG(DISTINCT pc2.color_name) AS colors
      FROM product_colors pc2
      WHERE pc2.product_id = p.product_id
        AND (w.product_color_id IS NULL OR pc2.product_color_id = w.product_color_id)
    ) c ON true

    -- ---------------------------------------------------------------------
    -- VARIANTS — real size+color pairs, restricted the same way, so the
    -- "Choose options" popup on the Wishlist screen can't offer a color
    -- other than the one that was actually wishlisted.
    -- ---------------------------------------------------------------------
    LEFT JOIN LATERAL (
      SELECT JSON_AGG(
        JSON_BUILD_OBJECT(
          'size', pv.size,
          'color', pc3.color_name,
          'stockQuantity', pv.stock_quantity
        )
      ) AS variants
      FROM product_variants pv
      LEFT JOIN product_colors pc3 ON pc3.product_color_id = pv.product_color_id
      WHERE pv.product_id = p.product_id
        AND (w.product_color_id IS NULL OR pv.product_color_id = w.product_color_id)
    ) vr ON true

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
