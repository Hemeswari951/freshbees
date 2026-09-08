const pool = require('../../config/db');

async function getSearchSuggestions(req, res) {
  try {
    const q = (req.query.q || '').trim();
    if (q.length < 1) {
      return res.status(200).json({ success: true, data: [] });
    }

    const likeParam = `%${q}%`;

    const { rows } = await pool.query(
      `
      (
        SELECT DISTINCT ON (s.shop_name)
          s.shop_name AS text,
          'shop' AS type,
          s.shop_id AS ref_id
        FROM shops s
        WHERE s.shop_name ILIKE $1
          AND s.is_blocked = false
        LIMIT 4
      )
      UNION ALL
      (
        SELECT DISTINCT ON (p.product_name)
          p.product_name AS text,
          'product' AS type,
          p.product_id AS ref_id
        FROM products p
        JOIN shops s ON s.shop_id = p.shop_id
        WHERE p.product_name ILIKE $1
          AND p.is_active = true
          AND s.is_blocked = false
        LIMIT 4
      )
      UNION ALL
      (
        SELECT DISTINCT ON (t.tag_name)
          t.tag_name AS text,
          'tag' AS type,
          t.tag_id AS ref_id
        FROM tags t
        JOIN product_tags pt ON pt.tag_id = t.tag_id
        JOIN products p ON p.product_id = pt.product_id
        JOIN shops s ON s.shop_id = p.shop_id
        WHERE t.tag_name ILIKE $1
          AND p.is_active = true
          AND s.is_blocked = false
        LIMIT 2
      )
      LIMIT 8
      `,
      [likeParam]
    );

    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    console.error('[customer getSearchSuggestions]', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch suggestions' });
  }
}

module.exports = { getSearchSuggestions };