const shopModel = require('../../models/shop_owner/profile.model');
const { uploadFile } = require('../../config/storageClient');

function toProfileShape(shop, extras = {}) {
  return {
    id: shop.shop_id,
    shopName: shop.shop_name,
    ownerName: shop.owner_name,
    logoUrl: shop.shop_logo,
    bannerUrl: shop.shop_banner,
    description: shop.shop_description,
    address: shop.address,
    city: shop.city,
    state: shop.state,
    pincode: shop.pincode,
    email: shop.email,
    phoneNumber: shop.phone,
    ownerLastLogin: shop.owner_last_login,
    createdAt: shop.created_at,
    ...extras,
  };
}

// GET /profile — now also pulls bank details + categories alongside
// the existing stat counts, all in parallel.
async function getProfileForShop(shopId) {
  const shop = await shopModel.findShopById(shopId);
  if (!shop) return null;

  const [productsCount, ordersCount, ratingSummary, bank, categories] =
    await Promise.all([
      shopModel.getProductCount(shopId),
      shopModel.getOrderCount(shopId),
      shopModel.getRatingSummary(shopId),
      shopModel.getBankDetails(shopId),
      shopModel.getCategories(shopId),
    ]);

  return toProfileShape(shop, {
    productsCount,
    ordersCount,
    avgRating: ratingSummary.avgRating,
    reviewCount: ratingSummary.reviewCount,
    categories,
    bankDetails: bank
      ? {
          accountNumber: bank.account_number,
          accountHolderName: bank.account_holder_name,
          bankName: bank.bank_name,
          ifscCode: bank.ifsc_code,
          gstNumber: bank.gst_number,
        }
      : null,
  });
}

async function updateProfileForShop(shopId, { body, files, shopOwnerId }) {
  const fields = {};
  if (body.shopName !== undefined) fields.shopName = body.shopName;
  if (body.ownerName !== undefined) fields.ownerName = body.ownerName;
  if (body.shopDescription !== undefined) {
    fields.shopDescription = body.shopDescription;
  }

  for (const file of files || []) {
    if (file.fieldname === 'logo') {
      fields.logoUrl = await uploadFile(file, `shops/${shopId}`, `${Date.now()}_logo`);
    } else if (file.fieldname === 'banner') {
      fields.bannerUrl = await uploadFile(file, `shops/${shopId}`, `${Date.now()}_banner`);
    }
  }

  const shop = await shopModel.updateShop(shopId, fields, shopOwnerId);
  if (!shop) return null;

  return toProfileShape(shop);
}

async function getReviewsForShop(shopId, { page = 1, limit = 20 } = {}) {
  const safePage = Math.max(1, page);
  const safeLimit = Math.min(50, limit);
  const offset = (safePage - 1) * safeLimit;

  const rows = await shopModel.getReviews(shopId, { limit: safeLimit, offset });

  return {
    reviews: rows.map((r) => ({
      id: r.review_id,
      rating: r.rating,
      reviewText: r.review_text,
      createdAt: r.created_at,
      customerName: `${r.first_name || ''} ${r.last_name || ''}`.trim(),
      productId: r.product_id,
      productName: r.product_name,
    })),
    page: safePage,
    limit: safeLimit,
  };
}

module.exports = {
  getProfileForShop,
  updateProfileForShop,
  getReviewsForShop,
};