const pool = require('../../config/db');
const productService = require('../../services/customer/product.service');
const imageSearchService = require('../../services/customer/image_search.service');
const { mapListItem } = require('./product.controller');

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

/**
 * POST /api/customer/search/image
 * multipart/form-data, field name: "image"
 *
 * Visual/image-based product search — used by the Home screen search
 * bar's camera icon (Take Photo / Choose from Gallery). Ranks the
 * catalog by visual (color/composition) similarity to the uploaded
 * photo and returns results in the exact same JSON shape as the normal
 * text search (`GET /products?search=`), so the Flutter app reuses its
 * existing product list/grid UI with zero special-casing.
 */
async function imageSearch(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image received. Please attach a photo to search with.',
      });
    }

    // Image search is deliberately different from text/voice search: it
    // should identify *the* product in the photo, not a ranked list with
    // the best guess buried at the top. So — unlike text search — we only
    // ever return the single closest match, never a scrollable page of
    // "close enough" runners-up.
    const matches = await imageSearchService.rankProductsByImage(req.file.buffer, {
      limit: 1,
    });

    if (matches.length === 0) {
      return res.status(200).json({
        success: true,
        data: [],
        message: "We couldn't find products that closely match this photo.",
      });
    }

    const productIds = matches.map((m) => m.productId);
    const rows = await productService.findPublicProductsByIds(productIds);

    // findPublicProductsByIds already returns rows in similarity order
    // (via array_position), so just map them straight through.
    return res.status(200).json({ success: true, data: rows.map(mapListItem) });
  } catch (err) {
    console.error('[customer imageSearch]', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to search by image. Please try again.',
    });
  }
}

module.exports = { getSearchSuggestions, imageSearch };