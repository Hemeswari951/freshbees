const pool = require('../../config/db'); // TODO: adjust to your actual pg Pool export path

/**
 * Fetch shops, optionally filtered by category name (e.g. 'Men').
 * A shop can belong to multiple categories (shop_categories is a
 * many-to-many junction table), so:
 *   - category_label / category_keys are an aggregate of ALL categories
 *     that shop belongs to (comma-joined) — just for display.
 *   - the `category` filter itself uses an EXISTS-style subquery so a
 *     shop matches if it belongs to AT LEAST that one category.
 *
 * @param {Object} params
 * @param {string} [params.category] - category name to filter by, case-insensitive.
 *                                      Omit (or pass falsy) for every shop.
 */
async function findShops({ category } = {}) {
  const values = [];
  let categoryFilter = '';

  if (category) {
    values.push(category.toLowerCase());
    categoryFilter = `
      AND s.shop_id IN (
        SELECT sc2.shop_id
        FROM shop_categories sc2
        JOIN categories c2 ON c2.category_id = sc2.category_id
        WHERE LOWER(c2.category_name) = $${values.length}
      )
    `;
  }

  const query = `
    SELECT
      s.shop_id,
      s.shop_name,
      s.shop_logo,
      s.shop_banner,
      s.city,
      s.state,
      STRING_AGG(DISTINCT c.category_name, ', ' ORDER BY c.category_name)         AS category_label,
      STRING_AGG(DISTINCT LOWER(c.category_name), ',' ORDER BY LOWER(c.category_name)) AS category_keys
    FROM shops s
    LEFT JOIN shop_categories sc ON sc.shop_id = s.shop_id
    LEFT JOIN categories c       ON c.category_id = sc.category_id
    WHERE s.is_blocked = FALSE
    ${categoryFilter}
    GROUP BY s.shop_id
    ORDER BY s.created_at DESC
  `;

  const { rows } = await pool.query(query, values);
  return rows;
}


module.exports = { findShops};