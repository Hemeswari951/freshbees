const bcrypt = require('bcrypt');
const shopModel = require('../../models/admin/shop.model');
const storageClient = require('../../config/storageClient');
const mailService = require('../shared/shopowner_welcomemail.service');

// ── Format DB row → Flutter shape ─────────────────────────────────────────
function formatShop(row) {
  return {
    shopId:        row.shop_id,
    shopName:      row.shop_name,
    shopLogo:      row.shop_logo    || null,
    shopBanner:    row.shop_banner  || null,
    ownerName:     row.owner_name   || '',
    ownerEmail:    row.owner_email  || '',
    ownerPhone:    row.owner_phone  || '',
    location:      row.city         || '',
    categories: row.category_names
    ? row.category_names.split(", ")
    : [],
    status:        row.is_blocked ? 'Blocked' : 'Active',
    isBlocked:     row.is_blocked,
    isActive:      row.is_active,
    totalProducts: Number(row.total_products || 0),
    totalOrders:   Number(row.total_orders   || 0),
    totalRevenue:  Number(row.total_revenue  || 0),
    avgRating:     Number(row.avg_rating     || 0),
    createdAt:     row.created_at,
  };
}

// ── Get all shops ──────────────────────────────────────────────────────────
async function getAllShops() {
  const rows = await shopModel.getAllShops();
  return rows.map(formatShop);
}


// ── Get single shop detail (shop + bank + settings + products + orders + payouts) ──
async function getShopDetail(shopId) {
  const [shop, bank, settings, products, orders, payouts] = await Promise.all([
    shopModel.getShopById(shopId),
    shopModel.getShopBankDetails(shopId),
    shopModel.getShopSettings(shopId),
    shopModel.getShopProducts(shopId),
    shopModel.getShopOrders(shopId),
    shopModel.getShopPayouts(shopId),
  ]);
  if (!shop) return null;

  return {
    ...formatShop(shop),
    address:        shop.address          || '',
    state:          shop.state            || '',
    pincode:        shop.pincode          || '',
    description:    shop.shop_description || '',
    ownerLastLogin: shop.owner_last_login,
    ownerImage:     shop.owner_image,
    blockedReason:  shop.blocked_reason,
    blockedAt:      shop.blocked_at,

    bankDetails: bank ? {
      accountNumber: bank.account_number,
      bankName:      bank.bank_name,
      ifscCode:      bank.ifsc_code,
      gstNumber:     bank.gst_number || '',
    } : null,

    settings: settings ? {
      commissionRate:       Number(settings.commission_rate),
      activateImmediately:  settings.activate_immediately,
      sendWelcomeEmail:     settings.send_welcome_email,
      allowProductUploads:  settings.allow_product_uploads,
      enablePayoutRequests: settings.enable_payout_requests,
    } : null,

    products: products.map(p => ({
      productId:   p.product_id,
      productName: p.product_name,
      subCategory: p.sub_category,
      category:    p.category,
      price:       Number(p.price),
      mrp:         p.mrp != null ? Number(p.mrp) : 0,
      stock:       p.stock,
      avgRating:   Number(p.avg_rating),
      image:       p.image,
    })),

    orders: orders.map(o => ({
      orderItemId:  o.order_item_id,
      orderId:      o.order_id,
      quantity:     o.quantity,
      price:        Number(o.price),
      itemStatus:   o.item_status,
      createdAt:    o.created_at,
      productName:  o.product_name,
      customerName: o.customer_name,
    })),

    payouts: payouts.map(p => ({
      payoutId:    p.payout_id,
      amount:      Number(p.amount),
      method:      p.method,
      status:      p.status,
      orderCount:  p.order_count,
      requestedAt: p.requested_at,
      completedAt: p.completed_at,
    })),
  };
}

// ── Create shop ────────────────────────────────────────────────────────────
async function createShop(payload, files) {
  // 1. Generate temporary password
  const rawPassword  = Math.random().toString(36).slice(-8); // e.g. "kx7mz3qw"
  const passwordHash = await bcrypt.hash(rawPassword, 10);

  // 2. Save everything to DB
  const { shopId } = await shopModel.createShop({
    ...payload,
    passwordHash,
    logoFile:   files.logo   ? files.logo[0]   : null,
    bannerFile: files.banner ? files.banner[0] : null,
  });

  // 4. Send welcome email with temporary password
  //    Only if admin toggled "Send welcome email" ON in Step 4
  const shouldMail = payload.sendWelcomeEmail === 'true'
    || payload.sendWelcomeEmail === true;

  if (shouldMail) {
    try {
      await mailService.sendShopOwnerWelcomeMail({
        ownerName:  payload.ownerName,
        ownerEmail: payload.ownerEmail,
        shopName:   payload.shopName,
        rawPassword,  // plain text — owner uses this for first login only
      });
    } catch (mailErr) {
      // Shop already saved — don't fail the whole request
      console.error('[createShop] Welcome email failed:', mailErr.message);
    }
  }

  return getShopDetail(shopId);
}


async function updateShopStatus(shopId, block, reason = null) {
  const updated = await shopModel.setShopBlockStatus(
    shopId,
    block,
    reason
  );

  if (!updated) {
    throw new Error("Shop not found");
  }

  return {
    shopId: updated.shop_id,
    isBlocked: updated.is_blocked,
    blockedReason: updated.blocked_reason,
    blockedAt: updated.blocked_at,
  };
}


async function updateBasicInfo(shopId, body) {

  return await shopModel.updateBasicInfo(

    shopId,

    body,

  );

}

async function updateOwnerInfo(shopId, body) {

  return await shopModel.updateOwnerInfo(

    shopId,

    body,

  );

}

async function updateBankInfo(shopId, body) {

  return await shopModel.updateBankInfo(

    shopId,

    body,

  );

}
async function updateSettings(shopId, body) {

  return await shopModel.updateSettings(

    shopId,

    body,

  );
}


module.exports = { getAllShops, createShop, getShopDetail, updateShopStatus, updateBasicInfo, updateOwnerInfo,updateBankInfo, updateSettings };