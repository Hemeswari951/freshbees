const pool = require('../../config/db');
const { deleteFile } = require('../../config/storageClient');

// All queries here are scoped by shop_id so a shop owner only ever
// sees/edits their OWN products — never another shop's.

const IMAGE_TYPES = ['front', 'back', 'side', 'zoom', '360'];

// ── discount_percent is NEVER stored — always calculated from mrp/price
// at read time. Reused in every SELECT below so list + detail + variants
// all compute it the exact same way. ──────────────────────────────────
const DISCOUNT_SQL = `
  CASE
    WHEN mrp IS NULL OR mrp <= 0 OR mrp <= price THEN 0
    ELSE ROUND(((mrp - price) / mrp) * 100)::INT
  END
`;

// Used by ProductsScreen (list) in the seller app, and by the customer-facing
// product grid. Thumbnail picks the FRONT image of the FIRST color a shop
// owner added (falls back to any image if front wasn't uploaded), so cards
// always show a consistent angle instead of a random photo.
async function findAllByShop(shopId) {
  const { rows } = await pool.query(
    `SELECT
       p.product_id, p.product_name, p.sku, p.description, p.sub_category,
       p.mrp, p.price, ${DISCOUNT_SQL.replace(/mrp/g, 'p.mrp').replace(/price/g, 'p.price')} AS discount_percent,
       p.is_active, p.created_at,
       cat.category_name, b.brand_name,
       COALESCE(img.image_url, NULL) AS thumbnail,
       COALESCE(v.total_stock, 0) AS total_stock,
       COALESCE(v.has_out_of_stock, FALSE) AS has_out_of_stock,
       COALESCE(v.has_low_stock, FALSE) AS has_low_stock
     FROM products p
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
       SELECT product_id,
         SUM(stock_quantity) AS total_stock,
         -- true if ANY variant of this product is completely out of stock
         BOOL_OR(stock_quantity = 0) AS has_out_of_stock,
         -- true if ANY variant has 1-4 units left (but isn't 0 — that's
         -- "out of stock", not "low stock")
         BOOL_OR(stock_quantity > 0 AND stock_quantity < 5) AS has_low_stock
       FROM product_variants GROUP BY product_id
     ) v ON v.product_id = p.product_id
     WHERE p.shop_id = $1
     ORDER BY p.created_at DESC`,
    [shopId]
  );
  return rows;

}

// Single product + every color, each with its own images (grouped by
// front/back/side/zoom) and its own size/stock rows, PLUS tags and
// category-specific extra attributes. Powers the product detail screen
// (owner side) and the customer PDP.
async function findByIdAndShop(productId, shopId) {
  const { rows } = await pool.query(
    `SELECT p.*,
       ${DISCOUNT_SQL.replace(/mrp/g, 'p.mrp').replace(/price/g, 'p.price')} AS discount_percent,
       cat.category_name, b.brand_name
     FROM products p
     LEFT JOIN categories cat ON cat.category_id = p.category_id
     LEFT JOIN brands b ON b.brand_id = p.brand_id
     WHERE p.product_id = $1 AND p.shop_id = $2`,
    [productId, shopId]
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

    // Approach 1: effective_price/effective_mrp resolve the per-variant
    // override — COALESCE(variant.price, product.price) — so the API
    // consumer never has to do that math client-side.
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

// shop_id is forced from the JWT (req.shopOwner.shopId) in the controller —
// never trust a shop_id sent from the client.
//
// NOTE: no discount_percent column value passed in here — it's calculated
// on read (see DISCOUNT_SQL above), never stored. SKU is intentionally NOT
// set here; it's generated right after the insert (see generateAndSetSku)
// once we have a product_id to build it from.
async function create(shopId, p) {
  const { rows } = await pool.query(
    `INSERT INTO products
       (shop_id, category_id, brand_id, product_name, description, sub_category,
        fabric, pattern, fit_type, sleeve_type, neck_type, occasion, wash_care,
        country_of_origin, mrp, price, is_active)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, TRUE)
     RETURNING *`,
    [
      shopId,
      p.categoryId,
      p.brandId,
      p.productName,
      p.description,
      p.subCategory || null,
      p.fabric || null,
      p.pattern || null,
      p.fitType || null,
      p.sleeveType || null,
      p.neckType || null,
      p.occasion || null,
      p.washCare || null,
      p.countryOfOrigin || 'India',
      p.mrp,
      p.price,
    ]
  );
  return rows[0];
}

// Backend-generated SKU — shop owner never types this. Format:
// SKU-SHOP<shopId>-PROD<productId>. Called once, right after create(),
// since product_id only exists after the insert.
async function generateAndSetSku(productId, shopId) {
  const sku = `SKU-SHOP${shopId}-PROD${productId}`;
  const { rows } = await pool.query(
    `UPDATE products SET sku = $1 WHERE product_id = $2 RETURNING *`,
    [sku, productId]
  );
  return rows[0];
}

async function addColor(productId, color) {
  const { rows } = await pool.query(
    `INSERT INTO product_colors (product_id, color_name, color_hex)
     VALUES ($1, $2, $3) RETURNING *`,
    [productId, color.colorName, color.colorHex || null]
  );
  return rows[0];
}

// images: [{ url, type }] — type must be one of front | back | side | zoom | 360
//
// startOrder: display_order to continue from. Defaults to 0 (fresh add
// flow — images start at display_order 1). On UPDATE flow, callers pass
// how many images are being KEPT so newly added ones append after them
// instead of restarting at 1 and colliding with kept rows.
async function addColorImages(productId, productColorId, images, startOrder = 0) {
  for (let i = 0; i < images.length; i++) {
    const type = IMAGE_TYPES.includes(images[i].type) ? images[i].type : 'front';
    await pool.query(
      `INSERT INTO product_images (product_id, product_color_id, image_url, image_type, display_order)
       VALUES ($1, $2, $3, $4, $5)`,
      [productId, productColorId, images[i].url, type, startOrder + i + 1]
    );
  }
}

// sizes: [{ size, stockQuantity, price, mrp }]
// `color` column is gone from product_variants (it duplicated
// product_colors.color_name) — color now comes ONLY through
// product_color_id. `price`/`mrp` are optional per-size overrides
// (Approach 1): left null/undefined here means "use the product's base
// price/mrp", resolved later via COALESCE wherever the product is read.
async function addColorVariants(productId, productColorId, sizes) {
  for (const s of sizes) {
    await pool.query(
      `INSERT INTO product_variants
         (product_id, product_color_id, size, price, mrp, stock_quantity)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        productId,
        productColorId,
        s.size,
        s.price ?? null,
        s.mrp ?? null,
        s.stockQuantity || 0,
      ]
    );
  }
}

// tagNames: string[] e.g. ["casual", "cotton", "summer"]
// Resolves each name to a tag_id (creating it if new — case-insensitive,
// stored lowercase/trimmed so "Summer" and "summer" don't become two
// rows), then maps the product to it in product_tags.
async function addProductTags(productId, tagNames) {
  for (const raw of tagNames || []) {
    const tagName = raw.trim().toLowerCase();
    if (!tagName) continue;

    const tagResult = await pool.query(
      `INSERT INTO tags (tag_name) VALUES ($1)
       ON CONFLICT (tag_name) DO UPDATE SET tag_name = EXCLUDED.tag_name
       RETURNING tag_id`,
      [tagName]
    );
    const tagId = tagResult.rows[0].tag_id;

    await pool.query(
      `INSERT INTO product_tags (product_id, tag_id) VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [productId, tagId]
    );
  }
}

// attributes: [{ label, value }] — category-specific extras (Pockets,
// Closure Type, Heel Height, etc.) that don't apply to every product.
async function addProductAttributes(productId, attributes) {
  let order = 1;
  for (const a of attributes || []) {
    if (!a.label || !a.label.trim()) continue;
    await pool.query(
      `INSERT INTO product_attributes (product_id, label, value, display_order)
       VALUES ($1, $2, $3, $4)`,
      [productId, a.label.trim(), (a.value || '').trim(), order++]
    );
  }
}

// Only updates if the product belongs to this shop (WHERE shop_id = $n).
// discount_percent removed — nothing to update, it's calculated on read.
async function updateByShop(productId, shopId, p) {
  const { rows } = await pool.query(
    `UPDATE products SET
       category_id = $1, brand_id = $2, product_name = $3, description = $4,
       sub_category = $5, fabric = $6, pattern = $7, fit_type = $8,
       sleeve_type = $9, neck_type = $10, occasion = $11, wash_care = $12,
       country_of_origin = $13, mrp = $14, price = $15,
       updated_at = CURRENT_TIMESTAMP
     WHERE product_id = $16 AND shop_id = $17
     RETURNING *`,
    [
      p.categoryId,
      p.brandId,
      p.productName,
      p.description,
      p.subCategory || null,
      p.fabric || null,
      p.pattern || null,
      p.fitType || null,
      p.sleeveType || null,
      p.neckType || null,
      p.occasion || null,
      p.washCare || null,
      p.countryOfOrigin || 'India',
      p.mrp,
      p.price,
      productId,
      shopId,
    ]
  );
  return rows[0] || null;
}

async function setActiveByShop(productId, shopId, isActive) {
  const { rows } = await pool.query(
    `UPDATE products SET is_active = $1 WHERE product_id = $2 AND shop_id = $3 RETURNING *`,
    [isActive, productId, shopId]
  );
  return rows[0] || null;
}

async function deleteByShop(productId, shopId) {
  const { rows } = await pool.query(
    `DELETE FROM products WHERE product_id = $1 AND shop_id = $2 RETURNING product_id`,
    [productId, shopId]
  );
  return rows[0] || null;
}

// Owner "Manage stock" screen — bump an existing variant's stock up or down
// WITHOUT touching products/product_colors. This is the function that keeps
// restock from ever creating a duplicate product: it only ever UPDATEs a
// variant_id that already exists and belongs to this shop.
async function adjustVariantStock(variantId, shopId, delta) {
  const { rows } = await pool.query(
    `UPDATE product_variants v
     SET stock_quantity = GREATEST(v.stock_quantity + $1, 0),
         updated_at = CURRENT_TIMESTAMP
     FROM products p
     WHERE v.variant_id = $2
       AND v.product_id = p.product_id
       AND p.shop_id = $3
     RETURNING v.*`,
    [delta, variantId, shopId]
  );
  return rows[0] || null;
}

// ─────────────────────────────────────────────────────────────────────
// NEW — supporting the update-product edit flow (image replace/delete,
// variant diffing, color diffing, tag/attribute full-replace).
// ─────────────────────────────────────────────────────────────────────

// Same shape as the color-loop inside findByIdAndShop, but standalone
// (no shop_id re-check — caller already confirmed productId belongs to
// this shop via updateByShop's WHERE clause) and returns raw image rows
// (image_id + image_url) so updateForShop can diff old vs. kept URLs.
async function findColorsWithDetailByProduct(productId) {
  const colorRows = await pool.query(
    `SELECT product_color_id, color_name, color_hex FROM product_colors
     WHERE product_id = $1 ORDER BY created_at ASC`,
    [productId]
  );

  const colors = [];
  for (const color of colorRows.rows) {
    const images = await pool.query(
      `SELECT image_id, image_url, image_type, display_order
       FROM product_images WHERE product_color_id = $1
       ORDER BY display_order ASC`,
      [color.product_color_id]
    );
    const variants = await pool.query(
      `SELECT variant_id, size, stock_quantity, price, mrp
       FROM product_variants WHERE product_color_id = $1`,
      [color.product_color_id]
    );
    colors.push({ ...color, images: images.rows, variants: variants.rows });
  }
  return colors;
}

async function updateColor(productColorId, colorName, colorHex) {
  const { rows } = await pool.query(
    `UPDATE product_colors SET color_name = $1, color_hex = $2
     WHERE product_color_id = $3 RETURNING *`,
    [colorName, colorHex || null, productColorId]
  );
  return rows[0] || null;
}

// Deletes the actual files from storage FIRST, then removes the DB rows.
// Order matters: if the DB delete happened first and the file delete
// failed afterwards, you'd have an orphaned file on disk with no DB row
// left pointing at it to clean it up later.
//
// images: [{ image_id, image_url, ... }] — the exact rows to remove.
async function deleteImagesFromStorageAndDb(images) {
  if (!images || !images.length) return;

  for (const img of images) {
    await deleteFile(img.image_url);
  }

  const ids = images.map((i) => i.image_id);
  await pool.query(
    `DELETE FROM product_images WHERE image_id = ANY($1::int[])`,
    [ids]
  );
}

async function updateVariant(variantId, s) {
  const { rows } = await pool.query(
    `UPDATE product_variants
     SET size = $1, stock_quantity = $2, price = $3, mrp = $4,
         updated_at = CURRENT_TIMESTAMP
     WHERE variant_id = $5
     RETURNING *`,
    [s.size, s.stockQuantity || 0, s.price ?? null, s.mrp ?? null, variantId]
  );
  return rows[0] || null;
}

async function deleteVariantsByIds(variantIds) {
  if (!variantIds || !variantIds.length) return;
  await pool.query(
    `DELETE FROM product_variants WHERE variant_id = ANY($1::int[])`,
    [variantIds]
  );
}

// Deletes a color entirely — variants first (FK constraint), then the
// color row itself. Caller MUST have already deleted this color's images
// via deleteImagesFromStorageAndDb before calling this, so no image rows
// (or files on disk) are left orphaned.
async function deleteColor(productColorId) {
  await pool.query(
    `DELETE FROM product_variants WHERE product_color_id = $1`,
    [productColorId]
  );
  await pool.query(
    `DELETE FROM product_colors WHERE product_color_id = $1`,
    [productColorId]
  );
}

// Full replace — simplest correct approach for an edit form. Avoids
// having to diff individual tag adds/removes; the edit screen always
// sends the complete current tag list.
async function replaceProductTags(productId, tagNames) {
  await pool.query(`DELETE FROM product_tags WHERE product_id = $1`, [productId]);
  await addProductTags(productId, tagNames);
}

async function replaceProductAttributes(productId, attributes) {
  await pool.query(`DELETE FROM product_attributes WHERE product_id = $1`, [productId]);
  await addProductAttributes(productId, attributes);
}

module.exports = {
  IMAGE_TYPES,
  findAllByShop,
  findByIdAndShop,
  create,
  generateAndSetSku,
  addColor,
  addColorImages,
  addColorVariants,
  addProductTags,
  addProductAttributes,
  updateByShop,
  setActiveByShop,
  deleteByShop,
  adjustVariantStock,
  // new — update flow
  findColorsWithDetailByProduct,
  updateColor,
  deleteImagesFromStorageAndDb,
  updateVariant,
  deleteVariantsByIds,
  deleteColor,
  replaceProductTags,
  replaceProductAttributes,
};