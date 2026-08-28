const homeModel = require('../../models/customer/home.model');

/**
 * Maps a raw DB row into the shape the Flutter ShopModel.fromJson()
 * expects: { id, shopName, category, categoryLabel, logoUrl, shopBanner,
 * locationLabel }.
 */
function mapShopRow(row) {
  return {
    id: row.shop_id,
    shopName: row.shop_name,
    category: row.category_keys || '',       // e.g. "men,women" — informational
    categoryLabel: row.category_label || '',  // e.g. "Men, Women" — display text
    logoUrl: row.shop_logo || null,
    shopBanner: row.shop_banner || null,
    locationLabel: [row.city, row.state].filter(Boolean).join(', '),
  };
}

/**
 * @param {Object} params
 * @param {string} [params.category] - 'Men' / 'Women' / 'Kids' / 'Beauty', or
 *                                      omitted/undefined for every shop (the
 *                                      "All" tab).
 */
async function getShops({ category } = {}) {
  const normalizedCategory =
    category && category.toLowerCase() !== 'all' ? category : undefined;

  const rows = await homeModel.findShops({ category: normalizedCategory });
  return rows.map(mapShopRow);
}

function mapShopDetailRow(row) {
  return {
    id: row.shop_id,
    shopName: row.shop_name,
    description: row.shop_description || null,
    shopLogo: row.shop_logo || null,
    shopBanner: row.shop_banner || null,
    categories: row.categories || [],
    city: row.city || null,
    state: row.state || null,
    address: row.address || null,
    rating: Number(row.rating) || 0,
    ratingCount: Number(row.rating_count) || 0,
    status: row.is_blocked ? 'Blocked' : 'Active',

    ownerName: row.owner_name || null,
    ownerEmail: row.owner_email || null,
    ownerPhone: row.owner_phone || null,
    ownerProfileImage: row.owner_profile_image || null,
  };
}

async function getShopDetails(shopId) {
  const row = await homeModel.findShopById(shopId);
  if (!row) return null;
  return mapShopDetailRow(row);
}

module.exports = { getShops, getShopDetails };