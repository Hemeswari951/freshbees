const pool = require('../../config/db');

async function findShopById(shopId) {
  const { rows } = await pool.query(
    `SELECT
       s.shop_id, s.shop_name, s.shop_logo, s.shop_banner,
       s.shop_description, s.address, s.city, s.state, s.pincode,
       s.created_at,
       so.shop_owner_id, so.full_name AS owner_name, so.email, so.phone,
       so.last_login AS owner_last_login
     FROM shops s
     LEFT JOIN shop_owners so ON so.shop_id = s.shop_id
     WHERE s.shop_id = $1
     ORDER BY so.shop_owner_id ASC
     LIMIT 1`,
    [shopId]
  );
  return rows[0] || null;
}

async function getProductCount(shopId) {
  const { rows } = await pool.query(
    `SELECT COUNT(*)::int AS count FROM products WHERE shop_id = $1`,
    [shopId]
  );
  return rows[0].count;
}

async function getOrderCount(shopId) {
  const { rows } = await pool.query(
    `SELECT COUNT(DISTINCT oi.order_id)::int AS count
     FROM order_items oi
     WHERE oi.shop_id = $1`,
    [shopId]
  );
  return rows[0].count;
}

async function getRatingSummary(shopId) {
  const { rows } = await pool.query(
    `SELECT
       COALESCE(ROUND(AVG(r.rating)::numeric, 1), 0) AS avg_rating,
       COUNT(r.review_id)::int AS review_count
     FROM reviews r
     JOIN products p ON p.product_id = r.product_id
     WHERE p.shop_id = $1`,
    [shopId]
  );
  return {
    avgRating: Number(rows[0].avg_rating),
    reviewCount: rows[0].review_count,
  };
}

// NEW — bank / account details set by admin (read-only for shop owner)
async function getBankDetails(shopId) {
  const { rows } = await pool.query(
    `SELECT account_number, account_holder_name, bank_name, ifsc_code, gst_number
     FROM shop_bank_details
     WHERE shop_id = $1`,
    [shopId]
  );
  return rows[0] || null;
}

// NEW — category names this shop sells under (Men / Women / Kids / Beauty)
async function getCategories(shopId) {
  const { rows } = await pool.query(
    `SELECT c.category_name
     FROM shop_categories sc
     JOIN categories c ON c.category_id = sc.category_id
     WHERE sc.shop_id = $1`,
    [shopId]
  );
  return rows.map((r) => r.category_name);
}

async function updateShop(shopId, fields, shopOwnerId) {
  const shopSets = [];
  const shopValues = [];
  let i = 1;

  if (fields.shopName !== undefined) {
    shopSets.push(`shop_name = $${i++}`);
    shopValues.push(fields.shopName);
  }
  if (fields.logoUrl !== undefined) {
    shopSets.push(`shop_logo = $${i++}`);
    shopValues.push(fields.logoUrl);
  }
  if (fields.bannerUrl !== undefined) {
    shopSets.push(`shop_banner = $${i++}`);
    shopValues.push(fields.bannerUrl);
  }
  if (fields.shopDescription !== undefined) {
    shopSets.push(`shop_description = $${i++}`);
    shopValues.push(fields.shopDescription);
  }

  if (shopSets.length) {
    shopValues.push(shopId);
    await pool.query(
      `UPDATE shops SET ${shopSets.join(', ')}, updated_at = CURRENT_TIMESTAMP
       WHERE shop_id = $${i}`,
      shopValues
    );
  }

  if (fields.ownerName !== undefined) {
    if (shopOwnerId) {
      await pool.query(
        `UPDATE shop_owners SET full_name = $1, updated_at = CURRENT_TIMESTAMP
         WHERE shop_owner_id = $2`,
        [fields.ownerName, shopOwnerId]
      );
    } else {
      await pool.query(
        `UPDATE shop_owners SET full_name = $1, updated_at = CURRENT_TIMESTAMP
         WHERE shop_owner_id = (
           SELECT shop_owner_id FROM shop_owners
           WHERE shop_id = $2 ORDER BY shop_owner_id ASC LIMIT 1
         )`,
        [fields.ownerName, shopId]
      );
    }
  }

  return findShopById(shopId);
}

async function getReviews(shopId, { limit = 20, offset = 0 } = {}) {
  const { rows } = await pool.query(
    `SELECT
       r.review_id, r.rating, r.review_text, r.created_at,
       c.first_name, c.last_name,
       p.product_id, p.product_name
     FROM reviews r
     JOIN products p ON p.product_id = r.product_id
     JOIN customers c ON c.customer_id = r.customer_id
     WHERE p.shop_id = $1
     ORDER BY r.created_at DESC
     LIMIT $2 OFFSET $3`,
    [shopId, limit, offset]
  );
  return rows;
}

module.exports = {
  findShopById,
  getProductCount,
  getOrderCount,
  getRatingSummary,
  getBankDetails,
  getCategories,
  updateShop,
  getReviews,
};