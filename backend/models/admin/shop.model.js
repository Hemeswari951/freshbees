const pool = require('../../config/db');
const storageClient = require('../../config/storageClient');

// ── List all shops with stats (products, orders, revenue, rating) ──────────
// Used by: ShopsScreen grid + stat cards
async function getAllShops() {
  const { rows } = await pool.query(`
    SELECT
    s.shop_id,
    s.shop_name,
    s.shop_logo,
    s.shop_banner,
    s.city,
    s.is_blocked,
    s.created_at,

    STRING_AGG(
        DISTINCT c.category_name,
        ', '
    ) AS category_names,

    so.full_name AS owner_name,
    so.email AS owner_email,
    so.phone AS owner_phone,

    COUNT(DISTINCT p.product_id) AS total_products,

    COUNT(DISTINCT oi.order_item_id) AS total_orders,

    COALESCE(
        SUM(oi.price * oi.quantity),
        0
    ) AS total_revenue,

    COALESCE(
        ROUND(
            AVG(r.rating)
            FILTER (
                WHERE r.rating IS NOT NULL
            ),
            1
        ),
        0
    ) AS avg_rating

FROM shops s

LEFT JOIN shop_categories sc
ON sc.shop_id = s.shop_id

LEFT JOIN categories c
ON c.category_id = sc.category_id

LEFT JOIN shop_owners so
ON so.shop_id = s.shop_id

LEFT JOIN products p
ON p.shop_id = s.shop_id

LEFT JOIN order_items oi
ON oi.shop_id = s.shop_id

LEFT JOIN reviews r
ON r.product_id = p.product_id

GROUP BY

s.shop_id,

so.full_name,

so.email,

so.phone

ORDER BY s.created_at DESC;


  `);
  return rows;
}

// ── Single shop (same columns as above, filtered by id) ───────────────────
// Used by: ShopDetailScreen header + Overview tab
async function getShopById(shopId) {
  const { rows } = await pool.query(`
    SELECT
      s.*,
      STRING_AGG(
    DISTINCT c.category_name,
    ', '
) AS category_names,
      so.full_name  AS owner_name,
      so.email      AS owner_email,
      so.phone      AS owner_phone,
      so.profile_image AS owner_image,
      so.last_login AS owner_last_login,

      COUNT(DISTINCT p.product_id)                      AS total_products,
      COUNT(DISTINCT oi.order_item_id)                  AS total_orders,
      COALESCE(SUM(oi.price * oi.quantity), 0)          AS total_revenue,
      COALESCE(ROUND(AVG(r.rating) FILTER (WHERE r.rating IS NOT NULL), 1), 0)
                                                        AS avg_rating
    FROM shops s
    LEFT JOIN shop_categories sc
ON sc.shop_id = s.shop_id

LEFT JOIN categories c
ON c.category_id = sc.category_id
    LEFT JOIN shop_owners so  ON so.shop_id    = s.shop_id
    LEFT JOIN products    p  ON p.shop_id      = s.shop_id
    LEFT JOIN order_items oi ON oi.shop_id     = s.shop_id
    LEFT JOIN reviews     r  ON r.product_id   = p.product_id
    WHERE s.shop_id = $1
    GROUP BY s.shop_id, 
             so.full_name, so.email, so.phone,
             so.profile_image, so.last_login
  `, [shopId]);
  return rows[0] || null;
}

// ── Bank details for a shop ────────────────────────────────────────────────
// Used by: ShopDetailScreen Overview tab → "Bank details" card
async function getShopBankDetails(shopId) {
  const { rows } = await pool.query(
    `SELECT * FROM shop_bank_details WHERE shop_id = $1`,
    [shopId]
  );
  return rows[0] || null;
}

// ── Settings for a shop ───────────────────────────────────────────────────
// Used by: ShopDetailScreen Overview tab → "Settings" card
async function getShopSettings(shopId) {
  const { rows } = await pool.query(
    `SELECT * FROM shop_settings WHERE shop_id = $1`,
    [shopId]
  );
  return rows[0] || null;
}

// ── Products for a shop (Products tab) ──────────────────────────────────
async function getShopProducts(shopId) {
  const { rows } = await pool.query(`
    SELECT
      p.product_id,
      p.product_name,
      p.description,
      p.sub_category,
      p.mrp,
      p.price,
      p.discount_percent,
      p.is_active,
      c.category_name AS category,          -- Men / Women / Kids / Beauty
      COALESCE(SUM(pv.stock_quantity), 0)::INT AS stock,
      COALESCE(ROUND(AVG(r.rating), 1), 0)   AS avg_rating,
      (
        SELECT image_url FROM product_images pi
        WHERE pi.product_id = p.product_id
        ORDER BY pi.display_order ASC LIMIT 1
      ) AS image
    FROM products p
    LEFT JOIN categories       c  ON c.category_id  = p.category_id
    LEFT JOIN product_variants pv ON pv.product_id  = p.product_id
    LEFT JOIN reviews          r  ON r.product_id   = p.product_id
    WHERE p.shop_id = $1
    GROUP BY p.product_id, c.category_name
    ORDER BY p.created_at DESC
  `, [shopId]);
  return rows;
}

// ── Orders for a shop (Orders tab) ───────────────────────────────────────
async function getShopOrders(shopId) {
  const { rows } = await pool.query(`
    SELECT
      oi.order_item_id,
      o.order_id,
      oi.quantity,
      oi.price,
      oi.item_status,
      oi.created_at,
      p.product_name,
      (c.first_name || ' ' || c.last_name) AS customer_name
    FROM order_items oi
    JOIN orders   o ON o.order_id   = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    JOIN customers    c ON c.customer_id    = o.customer_id
    WHERE oi.shop_id = $1
    ORDER BY oi.created_at DESC
  `, [shopId]);
  return rows;
}


// ── Payouts for a shop (Payouts tab) ─────────────────────────────────────
async function getShopPayouts(shopId) {
  const { rows } = await pool.query(`
    SELECT
      payout_id,
      amount,
      method,
      status,
      order_count,
      reference_number,
      requested_at,
      completed_at
    FROM payouts
    WHERE shop_id = $1
    ORDER BY requested_at DESC
  `, [shopId]);
  return rows;
}

// ── Create a full shop (all 4 form steps in one transaction) ──────────────
async function createShop({
  // Step 1 — Basic
  categoryIds,
  shopName,
  description,
  address,
  city,
  state,
  pincode,

  // Files (NOT URLs)
  logoFile,
  bannerFile,

  // Step 2 — Owner
  ownerName,
  ownerEmail,
  ownerPhone,
  passwordHash,

  // Step 3 — Bank
  accountNumber,
  bankName,
  ifscCode,
  gstNumber,

  // Step 4 — Settings
  commissionRate,
  activateImmediately,
  sendWelcomeEmail,
  allowProductUploads,
  enablePayoutRequests,
}) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // ------------------------------------------------------------------
    // 1. Create shop first
    // ------------------------------------------------------------------
    const shopRes = await client.query(
      `
      INSERT INTO shops
      (
        
        shop_name,
        shop_description,
        address,
        city,
        state,
        pincode
      )
      VALUES
      ($1,$2,$3,$4,$5,$6)
      RETURNING shop_id
      `,
      [
        
        shopName,
        description,
        address,
        city,
        state,
        pincode,
      ]
    );

    const shopId = shopRes.rows[0].shop_id;

    //--------------------------------------------------
// Save Shop Categories
//--------------------------------------------------

if (categoryIds && categoryIds.length > 0) {

    for (const categoryId of categoryIds) {

        await client.query(

            `
            INSERT INTO shop_categories
            (
                shop_id,
                category_id
            )
            VALUES
            ($1,$2)
            `,

            [

                shopId,

                categoryId,

            ]

        );

    }

}

    // ------------------------------------------------------------------
    // 2. Upload images using shop_id
    // ------------------------------------------------------------------

    const safeShopName = shopName
      .trim()
      .replace(/\s+/g, "_")
      .replace(/[^a-zA-Z0-9_]/g, "");

    let shopLogoUrl = null;
    let shopBannerUrl = null;

    if (logoFile) {
      shopLogoUrl = await storageClient.uploadFile(
        logoFile,
        "shops/logos",
        `${safeShopName}_${shopId}_logo`
      );
    }

    if (bannerFile) {
      shopBannerUrl = await storageClient.uploadFile(
        bannerFile,
        "shops/banners",
        `${safeShopName}_${shopId}_banner`
      );
    }
    console.log("logoUrl:", shopLogoUrl);
    console.log("bannerUrl:", shopBannerUrl);
    // ------------------------------------------------------------------
    // 3. Update shop with image paths
    // ------------------------------------------------------------------

    await client.query(
      `
      UPDATE shops
      SET
        shop_logo = $1,
        shop_banner = $2
      WHERE shop_id = $3
      `,
      [
        shopLogoUrl,
        shopBannerUrl,
        shopId,
      ]
    );

    // ------------------------------------------------------------------
    // 4. Insert owner
    // ------------------------------------------------------------------

    await client.query(
      `
      INSERT INTO shop_owners
      (
        shop_id,
        full_name,
        email,
        phone,
        password_hash
      )
      VALUES
      ($1,$2,$3,$4,$5)
      `,
      [
        shopId,
        ownerName,
        ownerEmail,
        ownerPhone,
        passwordHash,
      ]
    );

    // ------------------------------------------------------------------
    // 5. Insert bank details
    // ------------------------------------------------------------------

    await client.query(
      `
      INSERT INTO shop_bank_details
      (
        shop_id,
        account_number,
        bank_name,
        ifsc_code,
        gst_number
      )
      VALUES
      ($1,$2,$3,$4,$5)
      `,
      [
        shopId,
        accountNumber,
        bankName,
        ifscCode,
        gstNumber || null,
      ]
    );

    // ------------------------------------------------------------------
    // 6. Insert settings
    // ------------------------------------------------------------------

    await client.query(
      `
      INSERT INTO shop_settings
      (
        shop_id,
        commission_rate,
        activate_immediately,
        send_welcome_email,
        allow_product_uploads,
        enable_payout_requests
      )
      VALUES
      ($1,$2,$3,$4,$5,$6)
      `,
      [
        shopId,
        commissionRate ?? 10,
        activateImmediately ?? true,
        sendWelcomeEmail ?? true,
        allowProductUploads ?? true,
        enablePayoutRequests ?? false,
      ]
    );

    await client.query('COMMIT');

    return {
      shopId,
      shopLogoUrl,
      shopBannerUrl,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// ── Block / Unblock a shop ────────────────────────────────────────────────
// Used by: ShopDetailScreen "Block / Unblock" button
async function setShopBlockStatus(shopId, block, reason = null) {
  const { rows } = await pool.query(
    `
        UPDATE shops
        SET
            is_blocked = $2,
            blocked_reason = $3,
            blocked_at = $4,
            updated_at = NOW()
        WHERE shop_id = $1
        RETURNING
            shop_id,
            is_blocked,
            blocked_reason,
            blocked_at;
        `,
    [
      shopId,
      block,                     // true → blocked, false → active
      block ? reason : null,     // store reason only when blocking
      block ? new Date() : null  // store timestamp only when blocking
    ]
  );

  return rows[0];
}

async function updateBasicInfo(shopId, body) {

  const {

    shopName,
    description,
    categoryIds,
    address,
    city,
    state,
    pincode,

  } = body;

  // Update shop basic information
  const result = await pool.query(

    `
        UPDATE shops
        SET
            shop_name = $1,
            shop_description = $2,
            address = $3,
            city = $4,
            state = $5,
            pincode = $6,
            updated_at = NOW()
        WHERE shop_id = $7
        RETURNING *;
        `,

    [
      shopName,
      description,
      address,
      city,
      state,
      pincode,
      shopId,
    ]

  );

  // Remove old categories
  await pool.query(

    `
        DELETE FROM shop_categories
        WHERE shop_id = $1
        `,

    [shopId]

  );

  // Insert newly selected categories
  if (categoryIds && categoryIds.length > 0) {

    for (const categoryId of categoryIds) {

      await pool.query(

        `
                INSERT INTO shop_categories
                (
                    shop_id,
                    category_id
                )
                VALUES
                ($1,$2)
                `,

        [
          shopId,
          categoryId,
        ]

      );

    }

  }

  return result.rows[0];

}

async function updateOwnerInfo(shopId, body) {

  const {

    ownerName,

    ownerEmail,

    ownerPhone,

  } = body;

  const result = await pool.query(

    `
        UPDATE shop_owners

        SET

            full_name=$1,

            email=$2,

            phone=$3,

            updated_at=NOW()

        WHERE shop_id=$4

        RETURNING *;
        `,

    [

      ownerName,

      ownerEmail,

      ownerPhone,

      shopId,

    ]

  );

  return result.rows[0];

}
async function updateBankInfo(shopId, body) {

  const {

    accountHolderName,
    accountNumber,
    bankName,
    ifscCode,
    gstNumber,

  } = body;

  const result = await pool.query(

    `
        UPDATE shop_bank_details

        SET

            account_holder_name = $1,
            account_number = $2,
            bank_name = $3,
            ifsc_code = $4,
            gst_number = $5,
            updated_at = NOW()

        WHERE shop_id = $6

        RETURNING *;
        `,

    [

      accountHolderName,
      accountNumber,
      bankName,
      ifscCode,
      gstNumber,
      shopId,

    ]

  );

  return result.rows[0];

}
async function updateSettings(shopId, body) {

  const {

    commissionRate,
    activateImmediately,
    allowProductUploads,
    enablePayoutRequests,

  } = body;

  const result = await pool.query(

    `
        UPDATE shop_settings

        SET

            commission_rate = $1,
            activate_immediately = $2,
            allow_product_uploads = $3,
            enable_payout_requests = $4,
            updated_at = NOW()

        WHERE shop_id = $5

        RETURNING *;
        `,

    [

      commissionRate,
      activateImmediately,
      allowProductUploads,
      enablePayoutRequests,
      shopId,

    ]

  );

  return result.rows[0];

}

module.exports = {
  getAllShops,
  getShopById,
  getShopBankDetails,
  getShopSettings,
  getShopProducts,
  getShopOrders,
  getShopPayouts,
  createShop,
  setShopBlockStatus,
  updateBasicInfo,
  updateOwnerInfo,
  updateBankInfo,
  updateSettings
};
