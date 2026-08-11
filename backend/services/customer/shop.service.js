
const pool = require('../../config/db');

// ── List all ACTIVE (not blocked) shops for the customer app ──────────────
// Used by: GET /api/customer/shops  →  Home screen "Nearby Shops" section
async function getActiveShops() {
  const { rows } = await pool.query(`
    SELECT
      s.shop_id,
      s.shop_name,
      s.shop_description,
      s.shop_logo,
      s.shop_banner,
      s.address,
      s.city,
      s.state,
      s.is_blocked,
      s.created_at,

      STRING_AGG(
        DISTINCT c.category_name,
        ', '
      ) AS category_names,

      COALESCE(
        ROUND(
          AVG(r.rating) FILTER (WHERE r.rating IS NOT NULL),
          1
        ),
        0
      ) AS avg_rating

    FROM shops s

    LEFT JOIN shop_categories sc
      ON sc.shop_id = s.shop_id

    LEFT JOIN categories c
      ON c.category_id = sc.category_id

    LEFT JOIN products p
      ON p.shop_id = s.shop_id

    LEFT JOIN reviews r
      ON r.product_id = p.product_id

    WHERE s.is_blocked = false

    GROUP BY s.shop_id

    ORDER BY s.created_at DESC
  `);

  return rows;
}

// ── Single active shop by id (for a future shop-detail screen) ────────────
async function getShopById(shopId) {
  const { rows } = await pool.query(
    `
    SELECT
      s.shop_id,
      s.shop_name,
      s.shop_description,
      s.shop_logo,
      s.shop_banner,
      s.address,
      s.city,
      s.state,
      s.is_blocked,

      STRING_AGG(
        DISTINCT c.category_name,
        ', '
      ) AS category_names,

      COALESCE(
        ROUND(
          AVG(r.rating) FILTER (WHERE r.rating IS NOT NULL),
          1
        ),
        0
      ) AS avg_rating

    FROM shops s

    LEFT JOIN shop_categories sc
      ON sc.shop_id = s.shop_id

    LEFT JOIN categories c
      ON c.category_id = sc.category_id

    LEFT JOIN products p
      ON p.shop_id = s.shop_id

    LEFT JOIN reviews r
      ON r.product_id = p.product_id

    WHERE s.shop_id = $1

    GROUP BY s.shop_id
    `,
    [shopId]
  );

  return rows[0] || null;
}

module.exports = {
  getActiveShops,
  getShopById,
};
