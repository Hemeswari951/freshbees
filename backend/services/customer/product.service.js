

const pool = require('../../config/db');

const LOW_STOCK_THRESHOLD = 5;

function stockStatus(totalStock) {
  const stock = Number(totalStock) || 0;
  if (stock <= 0) return 'Out of stock';
  if (stock <= LOW_STOCK_THRESHOLD) return 'Only few left';
  return 'In stock';
}

const DISCOUNT_SQL = `
  CASE
    WHEN p.mrp IS NULL OR p.mrp <= 0 OR p.mrp <= p.price THEN 0
    ELSE ROUND(((p.mrp - p.price) / p.mrp) * 100)::INT
  END
`;

const FILTER_JOINS = `
  LEFT JOIN (
    SELECT pc.product_id, ARRAY_AGG(DISTINCT pv.size) AS sizes
    FROM product_variants pv
    JOIN product_colors pc ON pc.product_color_id = pv.product_color_id
    GROUP BY pc.product_id
  ) sizes_agg ON sizes_agg.product_id = p.product_id

  LEFT JOIN (
    SELECT product_id, ARRAY_AGG(DISTINCT color_name) AS colors
    FROM product_colors
    GROUP BY product_id
  ) colors_agg ON colors_agg.product_id = p.product_id

  LEFT JOIN (
    SELECT product_id, AVG(rating) AS avg_rating
    FROM reviews
    GROUP BY product_id
  ) rating_agg ON rating_agg.product_id = p.product_id
`;

const FILTER_SELECT_COLS = `
  COALESCE(sizes_agg.sizes, ARRAY[]::text[]) AS sizes,
  COALESCE(colors_agg.colors, ARRAY[]::text[]) AS colors,
  COALESCE(rating_agg.avg_rating, 0)::float AS rating
`;

const REVIEW_JOIN = `
  LEFT JOIN (
    SELECT product_id, COUNT(*) AS review_count, AVG(rating) AS avg_rating
    FROM reviews
    GROUP BY product_id
  ) rv ON rv.product_id = p.product_id
`;

const REVIEW_SELECT_COLS = `
  COALESCE(rv.review_count, 0) AS review_count
`;

// -----------------------------------------------------------------------------
// HOVER IMAGES (All angles for the active color)
// -----------------------------------------------------------------------------
const HOVER_IMAGES_JOIN = `
  LEFT JOIN LATERAL (
    SELECT COALESCE(
      json_agg(
        pi_hover.image_url
        ORDER BY
          CASE pi_hover.image_type
            WHEN 'front' THEN 0
            WHEN 'back' THEN 1
            WHEN 'side' THEN 2
            WHEN 'zoom' THEN 3
            WHEN '360' THEN 4
            ELSE 5
          END,
          pi_hover.display_order ASC
      ) FILTER (WHERE pi_hover.image_url IS NOT NULL),
      '[]'
    ) AS hover_images
    FROM product_images pi_hover
    WHERE pi_hover.product_color_id = COALESCE(active_color.product_color_id, img.product_color_id)
  ) hover_images_agg ON true
`;
 
const HOVER_IMAGES_SELECT_COL = `
  hover_images_agg.hover_images AS hover_images
`;

// ============================================================================
// HELPER: EXPLODE PRODUCTS BY MATCHING COLORS & SIZES
// ============================================================================
function buildColorSizeFilter(values, color, size) {
  let colorIdx = null;
  if (color && color.trim() !== '') {
    values.push(color.split(',').map(c => c.trim().toLowerCase()));
    colorIdx = values.length;
  }

  let sizeIdx = null;
  if (size && size.trim() !== '') {
    values.push(size.split(',').map(s => s.trim().toLowerCase()));
    sizeIdx = values.length;
  }

  let filterCondition = '';
  let activeColorJoin = '';

  if (colorIdx && sizeIdx) {
    // Explodes into multiple rows (one for each matched color) that ALSO have the matching size.
    activeColorJoin = `
      INNER JOIN product_colors active_color ON active_color.product_id = p.product_id
        AND LOWER(active_color.color_name) = ANY($${colorIdx}::text[])
        AND EXISTS (
          SELECT 1 FROM product_variants pvf
          WHERE pvf.product_color_id = active_color.product_color_id
            AND LOWER(pvf.size) = ANY($${sizeIdx}::text[])
        )
    `;
  } else if (colorIdx) {
    // Explodes into multiple rows for each matched color
    activeColorJoin = `
      INNER JOIN product_colors active_color ON active_color.product_id = p.product_id
        AND LOWER(active_color.color_name) = ANY($${colorIdx}::text[])
    `;
  } else if (sizeIdx) {
    // No color filter, standard query behavior, 1 row per product
    activeColorJoin = `
      LEFT JOIN LATERAL (SELECT NULL::int AS product_color_id) active_color ON true
    `;
    filterCondition = `
      AND EXISTS (
        SELECT 1 FROM product_variants pvf
        WHERE pvf.product_id = p.product_id
          AND LOWER(pvf.size) = ANY($${sizeIdx}::text[])
      )
    `;
  } else {
    activeColorJoin = `
      LEFT JOIN LATERAL (SELECT NULL::int AS product_color_id) active_color ON true
    `;
  }

  // Ensures that when the row explodes, the thumbnail specifically matches the exploded color
  const imgJoin = `
    LEFT JOIN LATERAL (
      SELECT pi.image_url, pc.product_color_id
      FROM product_images pi
      JOIN product_colors pc ON pc.product_color_id = pi.product_color_id
      WHERE pc.product_id = p.product_id
        AND (active_color.product_color_id IS NULL OR pc.product_color_id = active_color.product_color_id)
        ${(!colorIdx && sizeIdx) ? `
          AND EXISTS (
            SELECT 1 FROM product_variants pv_thumb
            WHERE pv_thumb.product_color_id = pc.product_color_id
              AND LOWER(pv_thumb.size) = ANY($${sizeIdx}::text[])
          )
        ` : ''}
      ORDER BY
        pc.created_at ASC,
        CASE pi.image_type WHEN 'front' THEN 0 ELSE 1 END,
        pi.display_order ASC
      LIMIT 1
    ) img ON true
  `;

  return { filterCondition, activeColorJoin, imgJoin };
}

// -----------------------------------------------------------------------------
// FIND ALL PUBLIC PRODUCTS
// -----------------------------------------------------------------------------
async function findAllPublicProducts({
  category, subCategory, minPrice, maxPrice, sortBy, color, size
} = {}) {
  const values = [];
  const conditions = [`p.is_active = true`, `s.is_blocked = false`];

  const filterGen = buildColorSizeFilter(values, color, size);
  if (filterGen.filterCondition) {
    conditions.push(filterGen.filterCondition.trim().replace(/^AND\s+/i, ''));
  }

  if (category && category.trim() !== '' && category.trim().toLowerCase() !== 'all') {
    values.push(category.trim().toLowerCase());
    conditions.push(`LOWER(cat.category_name) = $${values.length}`);
  }

  if (subCategory && subCategory.trim() !== '') {
    values.push(subCategory.trim().toLowerCase().replace(/[\s-]+/g, ''));
    const idx = values.length;
    conditions.push(`
      (
        LOWER(REGEXP_REPLACE(COALESCE(p.sub_category, ''), '[\\s-]+', '', 'g')) = $${idx}
        OR EXISTS (
          SELECT 1 FROM product_tags pt
          JOIN tags t ON t.tag_id = pt.tag_id
          WHERE pt.product_id = p.product_id
            AND LOWER(REGEXP_REPLACE(t.tag_name, '[\\s-]+', '', 'g')) = $${idx}
        )
      )
    `);
  }

  if (minPrice !== undefined && minPrice !== '') {
    values.push(Number(minPrice));
    conditions.push(`p.price >= $${values.length}`);
  }

  if (maxPrice !== undefined && maxPrice !== '') {
    values.push(Number(maxPrice));
    conditions.push(`p.price <= $${values.length}`);
  }

  let orderBy = 'p.created_at DESC';
  if (sortBy === 'price_asc') orderBy = 'p.price ASC';
  if (sortBy === 'price_desc') orderBy = 'p.price DESC';
  if (sortBy === 'discount') orderBy = `${DISCOUNT_SQL} DESC`;
  if (sortBy === 'popularity') orderBy = 'COALESCE(rv.review_count, 0) DESC';
  if (sortBy === 'rating') orderBy = 'COALESCE(rv.avg_rating, 0) DESC';

  const { rows } = await pool.query(`
    SELECT
      p.product_id, p.product_name, p.description, p.mrp, p.price,
      ${DISCOUNT_SQL} AS discount_percent,
      p.shop_id, s.shop_name, p.category_id, cat.category_name, p.sub_category, b.brand_name,
      COALESCE(img.image_url, NULL) AS thumbnail,
      COALESCE(active_color.product_color_id, img.product_color_id) AS product_color_id,
      COALESCE(v.total_stock, 0) AS total_stock,
      ${REVIEW_SELECT_COLS}, ${FILTER_SELECT_COLS}, ${HOVER_IMAGES_SELECT_COL}

    FROM products p
    JOIN shops s ON s.shop_id = p.shop_id
    LEFT JOIN categories cat ON cat.category_id = p.category_id
    LEFT JOIN brands b ON b.brand_id = p.brand_id

    ${filterGen.activeColorJoin}
    ${filterGen.imgJoin}

    LEFT JOIN (
      SELECT product_id, SUM(stock_quantity) AS total_stock
      FROM product_variants GROUP BY product_id
    ) v ON v.product_id = p.product_id

    ${HOVER_IMAGES_JOIN}
    ${REVIEW_JOIN}
    ${FILTER_JOINS}
    WHERE ${conditions.join(' AND ')}
    ORDER BY ${orderBy}
  `, values);

  return rows;
}

// -----------------------------------------------------------------------------
// PRODUCTS BY SHOP
// -----------------------------------------------------------------------------
async function findPublicProductsByShop(shopId, color, size) {
  const values = [shopId];
  const filterGen = buildColorSizeFilter(values, color, size);

  const { rows } = await pool.query(`
    SELECT
      p.product_id, p.product_name, p.description, p.mrp, p.price,
      ${DISCOUNT_SQL} AS discount_percent,
      p.shop_id, s.shop_name, p.category_id, cat.category_name, p.sub_category, b.brand_name,
      COALESCE(img.image_url, NULL) AS thumbnail,
      COALESCE(active_color.product_color_id, img.product_color_id) AS product_color_id,
      COALESCE(v.total_stock, 0) AS total_stock,
     ${REVIEW_SELECT_COLS}, ${FILTER_SELECT_COLS}, ${HOVER_IMAGES_SELECT_COL}
    FROM products p
    JOIN shops s ON s.shop_id = p.shop_id
    LEFT JOIN categories cat ON cat.category_id = p.category_id
    LEFT JOIN brands b ON b.brand_id = p.brand_id

    ${filterGen.activeColorJoin}
    ${filterGen.imgJoin}

    LEFT JOIN (
      SELECT product_id, SUM(stock_quantity) AS total_stock
      FROM product_variants GROUP BY product_id
    ) v ON v.product_id = p.product_id

    ${HOVER_IMAGES_JOIN}
    ${REVIEW_JOIN}
    ${FILTER_JOINS}
    WHERE p.is_active = true AND s.is_blocked = false AND p.shop_id = $1
      ${filterGen.filterCondition}
    ORDER BY p.created_at DESC
  `, values);

  return rows;
}

// -----------------------------------------------------------------------------
// SEARCH PRODUCTS
// -----------------------------------------------------------------------------
async function findPublicProductsBySearch(searchQuery, color, size) {
  const values = [`%${searchQuery}%`];
  const filterGen = buildColorSizeFilter(values, color, size);

  const { rows } = await pool.query(`
    SELECT
      p.product_id, p.product_name, p.description, p.mrp, p.price,
      ${DISCOUNT_SQL} AS discount_percent,
      p.shop_id, s.shop_name, p.category_id, cat.category_name, p.sub_category, b.brand_name,
      COALESCE(img.image_url, NULL) AS thumbnail,
      COALESCE(active_color.product_color_id, img.product_color_id) AS product_color_id,
      COALESCE(v.total_stock, 0) AS total_stock,
      ${REVIEW_SELECT_COLS}, ${FILTER_SELECT_COLS}, ${HOVER_IMAGES_SELECT_COL}
    FROM products p
    JOIN shops s ON s.shop_id = p.shop_id
    LEFT JOIN categories cat ON cat.category_id = p.category_id
    LEFT JOIN brands b ON b.brand_id = p.brand_id

    ${filterGen.activeColorJoin}
    ${filterGen.imgJoin}

    LEFT JOIN (
      SELECT product_id, SUM(stock_quantity) AS total_stock
      FROM product_variants GROUP BY product_id
    ) v ON v.product_id = p.product_id

    ${HOVER_IMAGES_JOIN}
    ${REVIEW_JOIN}
    ${FILTER_JOINS}
    WHERE p.is_active = true AND s.is_blocked = false
      AND (
        p.product_name ILIKE $1 OR p.sub_category ILIKE $1
        OR EXISTS (
          SELECT 1 FROM product_tags pt
          JOIN tags t ON t.tag_id = pt.tag_id
          WHERE pt.product_id = p.product_id AND t.tag_name ILIKE $1
        )
      )
      ${filterGen.filterCondition}
    ORDER BY p.created_at DESC
  `, values);

  return rows;
}

// -----------------------------------------------------------------------------
// SINGLE PRODUCT DETAIL
// -----------------------------------------------------------------------------
async function findPublicProductById(productId) {
  const { rows } = await pool.query(`
    SELECT
      p.product_id, p.product_name, p.description, p.sub_category, p.fabric, p.pattern, 
      p.fit_type, p.sleeve_type, p.neck_type, p.occasion, p.wash_care, p.country_of_origin,
      p.mrp, p.price, ${DISCOUNT_SQL} AS discount_percent, p.is_active,
      p.shop_id, s.shop_name, s.is_blocked AS shop_is_blocked,
      p.category_id, cat.category_name, b.brand_name
    FROM products p
    JOIN shops s ON s.shop_id = p.shop_id
    LEFT JOIN categories cat ON cat.category_id = p.category_id
    LEFT JOIN brands b ON b.brand_id = p.brand_id
    WHERE p.product_id = $1
  `, [productId]);

  const product = rows[0];
  if (!product || !product.is_active || product.shop_is_blocked) return null;

  const colorRows = await pool.query(`
    SELECT product_color_id, color_name, color_hex
    FROM product_colors WHERE product_id = $1 ORDER BY created_at ASC
  `, [productId]);

  const colors = [];
  for (const color of colorRows.rows) {
    const images = await pool.query(`
      SELECT image_id, image_url, image_type, display_order
      FROM product_images WHERE product_color_id = $1
      ORDER BY
        CASE image_type WHEN 'front' THEN 0 WHEN 'back' THEN 1 WHEN 'side' THEN 2 WHEN 'zoom' THEN 3 WHEN '360' THEN 4 ELSE 5 END,
        display_order ASC
    `, [color.product_color_id]);

    const variants = await pool.query(`
      SELECT
        v.variant_id, v.product_color_id, v.size, v.stock_quantity,
        COALESCE(v.price, p.price) AS price, COALESCE(v.mrp, p.mrp) AS mrp
      FROM product_variants v
      JOIN products p ON p.product_id = v.product_id
      WHERE v.product_color_id = $1 ORDER BY v.variant_id
    `, [color.product_color_id]);

    colors.push({ ...color, images: images.rows, variants: variants.rows });
  }

  const tags = await pool.query(`
    SELECT t.tag_id, t.tag_name
    FROM product_tags pt
    JOIN tags t ON t.tag_id = pt.tag_id
    WHERE pt.product_id = $1 ORDER BY t.tag_name
  `, [productId]);

  const attributes = await pool.query(`
    SELECT attribute_id, label, value, display_order
    FROM product_attributes WHERE product_id = $1
    ORDER BY display_order ASC, attribute_id ASC
  `, [productId]);

  const reviews = await pool.query(`
    SELECT review_id, customer_id, rating, review_text, created_at
    FROM reviews WHERE product_id = $1 ORDER BY created_at DESC
  `, [productId]);

  const totalStock = colors.reduce((sum, color) => {
    return sum + color.variants.reduce((vSum, variant) => vSum + Number(variant.stock_quantity || 0), 0);
  }, 0);

  return {
    ...product, total_stock: totalStock, colors,
    tags: tags.rows, attributes: attributes.rows, reviews: reviews.rows,
  };
}

// -----------------------------------------------------------------------------
// PRODUCTS BY ID LIST (preserves the given order)
// -----------------------------------------------------------------------------
// Used by image search: the ranking (by visual similarity) happens in
// image_search.service.js and hands back an ordered list of product IDs;
// this just hydrates those IDs into the same full row shape every other
// list endpoint returns, in that exact order (best match first).
// -----------------------------------------------------------------------------
async function findPublicProductsByIds(productIds) {
  if (!productIds || productIds.length === 0) return [];

  const { rows } = await pool.query(`
    SELECT
      p.product_id, p.product_name, p.description, p.mrp, p.price,
      ${DISCOUNT_SQL} AS discount_percent,
      p.shop_id, s.shop_name, p.category_id, cat.category_name, p.sub_category, b.brand_name,
      COALESCE(img.image_url, NULL) AS thumbnail,
      COALESCE(v.total_stock, 0) AS total_stock,
      ${REVIEW_SELECT_COLS}, ${FILTER_SELECT_COLS}
    FROM products p
    JOIN shops s ON s.shop_id = p.shop_id
    LEFT JOIN categories cat ON cat.category_id = p.category_id
    LEFT JOIN brands b ON b.brand_id = p.brand_id

    LEFT JOIN LATERAL (
      SELECT pi.image_url
      FROM product_images pi
      JOIN product_colors pc ON pc.product_color_id = pi.product_color_id
      WHERE pc.product_id = p.product_id
      ORDER BY
        pc.created_at ASC,
        CASE pi.image_type WHEN 'front' THEN 0 ELSE 1 END,
        pi.display_order ASC
      LIMIT 1
    ) img ON true

    LEFT JOIN (
      SELECT product_id, SUM(stock_quantity) AS total_stock
      FROM product_variants GROUP BY product_id
    ) v ON v.product_id = p.product_id

    ${REVIEW_JOIN}
    ${FILTER_JOINS}
    WHERE p.is_active = true AND s.is_blocked = false
      AND p.product_id = ANY($1::int[])
    ORDER BY array_position($1::int[], p.product_id)
  `, [productIds]);

  return rows;
}

// -----------------------------------------------------------------------------
// FILTER OPTIONS
// -----------------------------------------------------------------------------
async function findFilterOptions() {
  const colorsResult = await pool.query(`
    SELECT DISTINCT pc.color_name
    FROM product_colors pc
    JOIN products p ON p.product_id = pc.product_id
    JOIN shops s ON s.shop_id = p.shop_id
    WHERE p.is_active = true AND s.is_blocked = false
    ORDER BY pc.color_name
  `);

  const sizesResult = await pool.query(`
    SELECT DISTINCT pv.size
    FROM product_variants pv
    JOIN product_colors pc ON pc.product_color_id = pv.product_color_id
    JOIN products p ON p.product_id = pc.product_id
    JOIN shops s ON s.shop_id = p.shop_id
    WHERE p.is_active = true AND s.is_blocked = false
    ORDER BY pv.size
  `);

  return {
    colors: colorsResult.rows.map(row => row.color_name),
    sizes: sizesResult.rows.map(row => row.size),
  };
}

module.exports = {
  stockStatus, findAllPublicProducts, findPublicProductsByShop,
  findPublicProductsBySearch, findPublicProductById, findFilterOptions,
  findPublicProductsByIds, 
};