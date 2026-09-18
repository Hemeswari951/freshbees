const pool = require('../../config/db');

async function findShops({ category, latitude, longitude } = {}) {
  const values = [];
  let categoryFilter = '';
  let distanceSelect = 'NULL::numeric AS distance_km';
  let orderClause = 'ORDER BY s.created_at DESC';

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

  // Haversine distance in km, using PostgreSQL trig functions.
  // Shops without lat/lng get NULL distance and are pushed to the
  // end via the ORDER BY's NULLS LAST.
  if (latitude !== undefined && longitude !== undefined) {
    values.push(latitude);
    const latParam = `$${values.length}`;

    values.push(longitude);
    const lngParam = `$${values.length}`;

    distanceSelect = `
      CASE
        WHEN s.latitude IS NULL OR s.longitude IS NULL THEN NULL
        ELSE (
          6371 * acos(
            LEAST(1, GREATEST(-1,
              cos(radians(${latParam})) * cos(radians(s.latitude))
                * cos(radians(s.longitude) - radians(${lngParam}))
                + sin(radians(${latParam})) * sin(radians(s.latitude))
            ))
          )
        )
      END AS distance_km
    `;

    orderClause = 'ORDER BY distance_km ASC NULLS LAST, s.created_at DESC';
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
      ${distanceSelect},

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

    LEFT JOIN shop_categories sc ON sc.shop_id = s.shop_id
    LEFT JOIN categories c ON c.category_id = sc.category_id
    LEFT JOIN products p ON p.shop_id = s.shop_id
    LEFT JOIN reviews r ON r.product_id = p.product_id

    WHERE s.is_blocked = FALSE

    ${categoryFilter}

    GROUP BY s.shop_id

    ${orderClause}
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