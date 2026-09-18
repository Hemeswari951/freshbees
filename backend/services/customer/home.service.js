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
    category: row.category_keys || '',
    categoryLabel: row.category_label || '',
    logoUrl: row.shop_logo || null,
    shopBanner: row.shop_banner || null,
    locationLabel: [row.city, row.state].filter(Boolean).join(', '),
    distanceKm: row.distance_km !== undefined && row.distance_km !== null
      ? Number(row.distance_km)
      : null,
  };
}

async function getShops({ category, latitude, longitude } = {}) {
  const normalizedCategory =
    category && category.toLowerCase() !== 'all' ? category : undefined;

  const rows = await homeModel.findShops({
    category: normalizedCategory,
    latitude,
    longitude,
  });
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