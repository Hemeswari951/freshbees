const pool = require('../../config/db');

// Admin sees ACROSS all shops — unlike the shop owner model, nothing
// here filters by shop_id. Only read endpoints for now: list all
// products (any shop) and view one product by id (any shop).

// ── discount_percent is NEVER read from the stored column — the
// `products` table does have a `discount_percent INT DEFAULT 0` column,
// but nothing in this codebase writes to it, so it will always read back
// as 0/stale. We always recompute it fresh from mrp/price here instead.
// (Worth a migration to drop that column eventually, so a future reader
// doesn't accidentally trust it.)
const DISCOUNT_SQL = `
  CASE
    WHEN mrp IS NULL OR mrp <= 0 OR mrp <= price THEN 0
    ELSE ROUND(((mrp - price) / mrp) * 100)::INT
  END
`;

// filters: { shopId?, categoryId?, isActive?, search? } — all optional,
// used only to narrow the admin's view, never as an authorization check.
// Also joins shops (+ shop_owners via LATERAL) so admin can see whose
// product each row is.
async function findAllProductsAdmin(filters = {}) {
  const { shopId, categoryId, isActive, search } = filters;
  const conditions = [];
  const params = [];

  if (shopId) {
    params.push(shopId);
    conditions.push(`p.shop_id = $${params.length}`);
  }
  if (categoryId) {
    params.push(categoryId);
    conditions.push(`p.category_id = $${params.length}`);
  }
  if (isActive !== undefined) {
    params.push(isActive);
    conditions.push(`p.is_active = $${params.length}`);
  }
  if (search) {
    params.push(`%${search}%`);
    conditions.push(`p.product_name ILIKE $${params.length}`);
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const { rows } = await pool.query(
    `SELECT
       p.product_id, p.product_name, p.sku, p.description, p.sub_category,
       p.mrp, p.price, ${DISCOUNT_SQL.replace(/mrp/g, 'p.mrp').replace(/price/g, 'p.price')} AS discount_percent,
       p.is_active, p.created_at,
       p.shop_id, s.shop_name, own.full_name AS owner_name,
       cat.category_name, b.brand_name,
       COALESCE(img.image_url, NULL) AS thumbnail,
       COALESCE(v.total_stock, 0) AS total_stock,
       COALESCE(v.has_out_of_stock, FALSE) AS has_out_of_stock,
       COALESCE(v.has_low_stock, FALSE) AS has_low_stock
     FROM products p
     JOIN shops s ON s.shop_id = p.shop_id
     LEFT JOIN categories cat ON cat.category_id = p.category_id
     LEFT JOIN brands b ON b.brand_id = p.brand_id
     -- owner_name lives on shop_owners, not shops. A shop could in theory
     -- have more than one shop_owners row (no UNIQUE constraint on
     -- shop_owners.shop_id), so a plain JOIN here would risk duplicating
     -- product rows one-per-owner. LATERAL + LIMIT 1 picks a single,
     -- deterministic owner (earliest created) the same way the thumbnail
     -- LATERAL below picks a single image.
     LEFT JOIN LATERAL (
       SELECT so.full_name
       FROM shop_owners so
       WHERE so.shop_id = s.shop_id
       ORDER BY so.created_at ASC
       LIMIT 1
     ) own ON true
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
       SELECT product_id,
         SUM(stock_quantity) AS total_stock,
         BOOL_OR(stock_quantity = 0) AS has_out_of_stock,
         BOOL_OR(stock_quantity > 0 AND stock_quantity < 5) AS has_low_stock
       FROM product_variants GROUP BY product_id
     ) v ON v.product_id = p.product_id
     ${whereClause}
     ORDER BY p.created_at DESC`,
    params
  );
  return rows;
}

// Same shape as shop owner's findProductById — colors, images, variants,
// tags, attributes — just no shop_id filter, so admin can open any
// product by id regardless of which shop it belongs to.
async function findProductByIdAdmin(productId) {
  const { rows } = await pool.query(
    `SELECT
       -- Explicit column list (NOT p.*) so the products table's stored,
       -- always-stale discount_percent column never lands in this result
       -- — only the freshly computed one below does. Using p.* here would
       -- silently pull both under the same key and rely on column order
       -- for the computed one to "win".
       p.product_id, p.shop_id, p.category_id, p.brand_id, p.product_name,
       p.sku, p.description, p.sub_category, p.fabric, p.pattern,
       p.fit_type, p.sleeve_type, p.neck_type, p.occasion, p.wash_care,
       p.country_of_origin, p.mrp, p.price, p.is_active,
       p.created_at, p.updated_at,
       ${DISCOUNT_SQL.replace(/mrp/g, 'p.mrp').replace(/price/g, 'p.price')} AS discount_percent,
       s.shop_name, own.full_name AS owner_name,
       cat.category_name, b.brand_name
     FROM products p
     JOIN shops s ON s.shop_id = p.shop_id
     LEFT JOIN categories cat ON cat.category_id = p.category_id
     LEFT JOIN brands b ON b.brand_id = p.brand_id
     LEFT JOIN LATERAL (
       SELECT so.full_name
       FROM shop_owners so
       WHERE so.shop_id = s.shop_id
       ORDER BY so.created_at ASC
       LIMIT 1
     ) own ON true
     WHERE p.product_id = $1`,
    [productId]
  );
  const product = rows[0];
  if (!product) return null;

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
         v.variant_id, v.size, v.stock_quantity,
         v.price, v.mrp,
         COALESCE(v.price, p.price) AS effective_price,
         COALESCE(v.mrp, p.mrp) AS effective_mrp,
         CASE
           WHEN COALESCE(v.mrp, p.mrp) IS NULL
                OR COALESCE(v.mrp, p.mrp) <= 0
                OR COALESCE(v.mrp, p.mrp) <= COALESCE(v.price, p.price)
             THEN 0
           ELSE ROUND(
             ((COALESCE(v.mrp, p.mrp) - COALESCE(v.price, p.price))
               / COALESCE(v.mrp, p.mrp)) * 100
           )
         END AS discount_percent
       FROM product_variants v
       JOIN products p ON p.product_id = v.product_id
       WHERE v.product_color_id = $1
       ORDER BY v.variant_id`,
      [color.product_color_id]
    );
    colors.push({ ...color, images: images.rows, variants: variants.rows });
  }

  const tags = await pool.query(
    `SELECT t.tag_name
     FROM product_tags pt
     JOIN tags t ON t.tag_id = pt.tag_id
     WHERE pt.product_id = $1
     ORDER BY t.tag_name`,
    [productId]
  );

  const attributes = await pool.query(
    `SELECT label, value
     FROM product_attributes
     WHERE product_id = $1
     ORDER BY display_order ASC, attribute_id ASC`,
    [productId]
  );

  return {
    ...product,
    colors,
    tags: tags.rows.map((r) => r.tag_name),
    attributes: attributes.rows,
  };
}

async function updateProductStatus(productId, isActive) {
  const result = await pool.query(
    `
    UPDATE products
    SET
      is_active = $1,
      updated_at = CURRENT_TIMESTAMP
    WHERE product_id = $2
    RETURNING product_id
    `,
    [isActive, productId]
  );

  return result.rowCount > 0;
}

module.exports = {
  updateProductStatus,
  findAllProductsAdmin,
  findProductByIdAdmin,
};