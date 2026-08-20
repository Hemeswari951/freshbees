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


module.exports = { getShops};