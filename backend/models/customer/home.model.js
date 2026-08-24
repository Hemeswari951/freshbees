const pool = require('../../config/db');

async function findShops({ category } = {}) {
  const values = [];
  let categoryFilter = '';

  if (category) {
    values.push(category.toLowerCase());

    categoryFilter = `
      AND EXISTS (
        SELECT 1
        FROM shop_categories sc2
        JOIN categories c2
          ON c2.category_id = sc2.category_id
        WHERE sc2.shop_id = s.shop_id
          AND LOWER(c2.category_name) = $${values.length}
      )
    `;
  }

  const query = `
    SELECT
      s.shop_id,
      s.shop_name,
      s.shop_logo,
      s.shop_banner,
      s.shop_description,
      s.address,
      s.city,
      s.state,

      COALESCE(
        ARRAY_AGG(
          DISTINCT c.category_name
          ORDER BY c.category_name
        ) FILTER (WHERE c.category_name IS NOT NULL),
        '{}'
      ) AS categories,

      COALESCE(
        ROUND(AVG(r.rating)::numeric, 1),
        0
      ) AS rating,

      COUNT(r.review_id) AS rating_count

    FROM shops s

    LEFT JOIN shop_categories sc
      ON sc.shop_id = s.shop_id

    LEFT JOIN categories c
      ON c.category_id = sc.category_id

    LEFT JOIN products p
      ON p.shop_id = s.shop_id

    LEFT JOIN reviews r
      ON r.product_id = p.product_id

    WHERE s.is_blocked = FALSE

    ${categoryFilter}

    GROUP BY s.shop_id

    ORDER BY s.created_at DESC
  `;

  const { rows } = await pool.query(query, values);

  return rows;
}

async function findShopById(shopId) {
  const query = `
    SELECT
      s.shop_id,
      s.shop_name,
      s.shop_logo,
      s.shop_banner,
      s.shop_description,
      s.address,
      s.city,
      s.state,
      s.is_blocked,

      so.full_name     AS owner_name,
      so.email         AS owner_email,
      so.phone         AS owner_phone,
      so.profile_image AS owner_profile_image,

      COALESCE(
        ARRAY_AGG(
          DISTINCT c.category_name
          ORDER BY c.category_name
        ) FILTER (WHERE c.category_name IS NOT NULL),
        '{}'
      ) AS categories,

      COALESCE(ROUND(AVG(r.rating)::numeric, 1), 0) AS rating,
      COUNT(r.review_id) AS rating_count

    FROM shops s

    LEFT JOIN shop_owners so ON so.shop_id = s.shop_id
    LEFT JOIN shop_categories sc ON sc.shop_id = s.shop_id
    LEFT JOIN categories c ON c.category_id = sc.category_id
    LEFT JOIN products p ON p.shop_id = s.shop_id
    LEFT JOIN reviews r ON r.product_id = p.product_id

    WHERE s.shop_id = $1
      AND s.is_blocked = FALSE

    GROUP BY s.shop_id, so.full_name, so.email, so.phone, so.profile_image
  `;

  const { rows } = await pool.query(query, [shopId]);
  return rows[0] || null; // null = not found OR blocked — controller returns 404 either way
}

module.exports = {
  findShops,
  findShopById,
};