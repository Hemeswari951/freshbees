const pool = require('../../config/db');

const LOW_STOCK_THRESHOLD = 5;

function stockStatus(totalStock) {
  const stock = Number(totalStock) || 0;
  if (stock <= 0) return 'Out of stock';
  if (stock <= LOW_STOCK_THRESHOLD) return 'Only few left';
  return 'In stock';
}

// discount_percent is never stored — always derived from mrp/price, same
// formula used on the shop-owner side (see shop_owner/product.model.js).
const DISCOUNT_SQL = `
  CASE
    WHEN p.mrp IS NULL OR p.mrp <= 0 OR p.mrp <= p.price THEN 0
    ELSE ROUND(((p.mrp - p.price) / p.mrp) * 100)::INT
  END
`;

// Shared JOIN block that adds sizes/colors/rating to any product-list
// query below. Needed by the Flutter filter panel (Size, Color, Rating
// filters) — without these three columns the client has nothing to
// filter on.
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

// ── Product grid for Home "Recommended For You" / Explore ─────────────────
async function findAllPublicProducts() {
  const { rows } = await pool.query(`
    SELECT
      p.product_id,
      p.product_name,
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
      ${FILTER_SELECT_COLS}
    FROM products p
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
    ${FILTER_JOINS}
    WHERE p.is_active = true
      AND s.is_blocked = false
    ORDER BY p.created_at DESC
  `);
  return rows;
}

// ── Single product detail (public PDP) ─────────────────────────────────────
async function findPublicProductById(productId) {
  const { rows } = await pool.query(
    `
    SELECT
      p.product_id, p.product_name, p.description, p.sub_category,
      p.fabric, p.pattern, p.fit_type, p.sleeve_type, p.neck_type,
      p.occasion, p.wash_care, p.country_of_origin,
      p.mrp, p.price, ${DISCOUNT_SQL} AS discount_percent,
      p.is_active,
      p.shop_id, s.shop_name, s.is_blocked AS shop_is_blocked,
      p.category_id, cat.category_name,
      b.brand_name
    FROM products p
    JOIN shops s ON s.shop_id = p.shop_id
    LEFT JOIN categories cat ON cat.category_id = p.category_id
    LEFT JOIN brands b ON b.brand_id = p.brand_id
    WHERE p.product_id = $1
    `,
    [productId]
  );

  const product = rows[0];
  if (!product) return null;
  if (!product.is_active || product.shop_is_blocked) return null;

  const colorRows = await pool.query(
    `SELECT product_color_id, color_name, color_hex FROM product_colors
     WHERE product_id = $1 ORDER BY created_at ASC`,
    [productId]
  );

  const colors = [];
  for (const color of colorRows.rows) {
    const images = await pool.query(
      `SELECT image_id, image_url, image_type, display_order
       FROM product_images
       WHERE product_color_id = $1
       ORDER BY CASE image_type
         WHEN 'front' THEN 0 WHEN 'back' THEN 1
         WHEN 'side' THEN 2 WHEN 'zoom' THEN 3
         WHEN '360' THEN 4 ELSE 5 END,
         display_order ASC`,
      [color.product_color_id]
    );

    const variants = await pool.query(
      `SELECT
         v.variant_id, v.product_color_id, v.size, v.stock_quantity,
         COALESCE(v.price, p.price) AS price,
         COALESCE(v.mrp, p.mrp) AS mrp
       FROM product_variants v
       JOIN products p ON p.product_id = v.product_id
       WHERE v.product_color_id = $1
       ORDER BY v.variant_id`,
      [color.product_color_id]
    );

    colors.push({ ...color, images: images.rows, variants: variants.rows });
  }

  const tags = await pool.query(
    `SELECT t.tag_id, t.tag_name
     FROM product_tags pt
     JOIN tags t ON t.tag_id = pt.tag_id
     WHERE pt.product_id = $1
     ORDER BY t.tag_name`,
    [productId]
  );

  const attributes = await pool.query(
    `SELECT attribute_id, label, value, display_order
     FROM product_attributes
     WHERE product_id = $1
     ORDER BY display_order ASC, attribute_id ASC`,
    [productId]
  );

  const reviews = await pool.query(
    `SELECT review_id, customer_id, rating, review_text, created_at
     FROM reviews
     WHERE product_id = $1
     ORDER BY created_at DESC`,
    [productId]
  );

  const totalStock = colors.reduce(
    (sum, c) => sum + c.variants.reduce((s, v) => s + Number(v.stock_quantity), 0),
    0
  );

  return {
    ...product,
    total_stock: totalStock,
    colors,
    tags: tags.rows,
    attributes: attributes.rows,
    reviews: reviews.rows,
  };
}

// ── Product grid scoped to one shop (customer Shop Detail screen) ─────────
async function findPublicProductsByShop(shopId) {
  const { rows } = await pool.query(
    `
    SELECT
      p.product_id,
      p.product_name,
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
      ${FILTER_SELECT_COLS}
    FROM products p
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
    ${FILTER_JOINS}
    WHERE p.is_active = true
      AND s.is_blocked = false
      AND p.shop_id = $1
    ORDER BY p.created_at DESC
    `,
    [shopId]
  );
  return rows;
}

// ── Product grid for search — matches product_name OR tag_name ───────────
async function findPublicProductsBySearch(searchQuery) {
  const { rows } = await pool.query(
    `
    SELECT
      p.product_id,
      p.product_name,
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
      ${FILTER_SELECT_COLS}
    FROM products p
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
    ${FILTER_JOINS}
    WHERE p.is_active = true
      AND s.is_blocked = false
      AND (
        p.product_name ILIKE $1
        OR EXISTS (
          SELECT 1 FROM product_tags pt
          JOIN tags t ON t.tag_id = pt.tag_id
          WHERE pt.product_id = p.product_id
            AND t.tag_name ILIKE $1
        )
      )
    ORDER BY p.created_at DESC
    `,
    [`%${searchQuery}%`]
  );
  return rows;
}

// ── Distinct filter option values — colors & sizes actually in use ────────
// Used to populate the Flutter filter panel's Color/Size lists dynamically
// instead of a hardcoded list that goes stale the moment a shop owner adds
// a new color/size. Only pulls from active products in unblocked shops —
// same visibility rule as the product-list queries above.
async function findFilterOptions() {
  const colorsResult = await pool.query(`
    SELECT DISTINCT pc.color_name
    FROM product_colors pc
    JOIN products p ON p.product_id = pc.product_id
    JOIN shops s ON s.shop_id = p.shop_id
    WHERE p.is_active = true
      AND s.is_blocked = false
    ORDER BY pc.color_name
  `);

  const sizesResult = await pool.query(`
    SELECT DISTINCT pv.size
    FROM product_variants pv
    JOIN product_colors pc ON pc.product_color_id = pv.product_color_id
    JOIN products p ON p.product_id = pc.product_id
    JOIN shops s ON s.shop_id = p.shop_id
    WHERE p.is_active = true
      AND s.is_blocked = false
    ORDER BY pv.size
  `);

  return {
    colors: colorsResult.rows.map((r) => r.color_name),
    sizes: sizesResult.rows.map((r) => r.size),
  };
}

module.exports = {
  stockStatus,
  findAllPublicProducts,
  findPublicProductsByShop,
  findPublicProductsBySearch,
  findPublicProductById,
  findFilterOptions,
};