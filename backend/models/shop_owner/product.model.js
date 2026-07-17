const pool = require('../../config/db');

// All queries here are scoped by shop_id so a shop owner only ever
// sees/edits their OWN products — never another shop's.

const IMAGE_TYPES = ['front', 'back', 'side', 'zoom', '360'];

// Used by ProductsScreen (list) in the seller app, and by the customer-facing
// product grid. Thumbnail picks the FRONT image of the FIRST color a shop
// owner added (falls back to any image if front wasn't uploaded), so cards
// always show a consistent angle instead of a random photo.
async function findAllByShop(shopId) {
  const { rows } = await pool.query(
    `SELECT
       p.product_id, p.product_name, p.description, p.mrp, p.price,
       p.discount_percent, p.is_active, p.created_at,
       cat.category_name, b.brand_name,
       COALESCE(img.image_url, NULL) AS thumbnail,
       COALESCE(v.total_stock, 0) AS total_stock
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
       SELECT product_id, SUM(stock_quantity) AS total_stock
       FROM product_variants GROUP BY product_id
     ) v ON v.product_id = p.product_id
     WHERE p.shop_id = $1
     ORDER BY p.created_at DESC`,
    [shopId]
  );
  return rows;
}

// Single product + every color, each with its own images (grouped by
// front/back/side/zoom) and its own size/stock rows. Powers the product
// detail screen (owner side) and the customer PDP.
async function findByIdAndShop(productId, shopId) {
  const { rows } = await pool.query(
    `SELECT p.*, cat.category_name, b.brand_name
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
    const variants = await pool.query(
      `SELECT variant_id, size, stock_quantity FROM product_variants
       WHERE product_color_id = $1 ORDER BY variant_id`,
      [color.product_color_id]
    );
    colors.push({ ...color, images: images.rows, variants: variants.rows });
  }

  return { ...product, colors };
}

// shop_id is forced from the JWT (req.shopOwner.shopId) in the controller —
// never trust a shop_id sent from the client.
async function create(shopId, p) {
  const { rows } = await pool.query(
    `INSERT INTO products
       (shop_id, category_id, brand_id, product_name, description, mrp, price, discount_percent, is_active)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, TRUE)
     RETURNING *`,
    [shopId, p.categoryId, p.brandId, p.productName, p.description, p.mrp, p.price, p.discountPercent || 0]
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
async function addColorImages(productId, productColorId, images) {
  for (let i = 0; i < images.length; i++) {
    const type = IMAGE_TYPES.includes(images[i].type) ? images[i].type : 'front';
    await pool.query(
      `INSERT INTO product_images (product_id, product_color_id, image_url, image_type, display_order)
       VALUES ($1, $2, $3, $4, $5)`,
      [productId, productColorId, images[i].url, type, i + 1]
    );
  }
}

// sizes: [{ size, stockQuantity }]
async function addColorVariants(productId, productColorId, colorName, sizes) {
  for (const s of sizes) {
    await pool.query(
      `INSERT INTO product_variants (product_id, product_color_id, size, color, stock_quantity)
       VALUES ($1, $2, $3, $4, $5)`,
      [productId, productColorId, s.size, colorName, s.stockQuantity || 0]
    );
  }
}

// Only updates if the product belongs to this shop (WHERE shop_id = $n).
async function updateByShop(productId, shopId, p) {
  const { rows } = await pool.query(
    `UPDATE products SET
       category_id = $1, brand_id = $2, product_name = $3, description = $4,
       mrp = $5, price = $6, discount_percent = $7
     WHERE product_id = $8 AND shop_id = $9
     RETURNING *`,
    [p.categoryId, p.brandId, p.productName, p.description, p.mrp, p.price, p.discountPercent || 0, productId, shopId]
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

module.exports = {
  IMAGE_TYPES,
  findAllByShop,
  findByIdAndShop,
  create,
  addColor,
  addColorImages,
  addColorVariants,
  updateByShop,
  setActiveByShop,
  deleteByShop,
  adjustVariantStock,
};