
const shopService = require('../../services/customer/shop.service');

// ── Shared row → JSON mapper ────────────────────────────────────────────
// Matches the Flutter ShopModel.fromJson() field names exactly:
//   id, shopName, description, shopLogo, shopBanner,
//   categories (array), city, state, address, rating, status
function mapShop(row) {
  return {
    id: row.shop_id,
    shopName: row.shop_name,
    description: row.shop_description,
    shopLogo: row.shop_logo,
    shopBanner: row.shop_banner,
    categories: row.category_names ? row.category_names.split(', ') : [],
    city: row.city,
    state: row.state,
    address: row.address,
    rating: Number(row.avg_rating) || 0,
    status: row.is_blocked ? 'Blocked' : 'Active',
  };
}

// GET /api/customer/shops
// → Returns all active shops for the "Nearby Shops" section on Home
async function listShops(req, res) {
  try {
    const shops = await shopService.getActiveShops();
    res.json({ success: true, data: shops.map(mapShop) });
  } catch (err) {
    console.error('[customer listShops]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch shops' });
  }
}

// GET /api/customer/shops/:id
// → Returns a single shop (for a future shop-detail screen)
async function getShop(req, res) {
  try {
    const shop = await shopService.getShopById(req.params.id);

    if (!shop || shop.is_blocked) {
      return res.status(404).json({ success: false, message: 'Shop not found' });
    }

    res.json({ success: true, data: mapShop(shop) });
  } catch (err) {
    console.error('[customer getShop]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch shop' });
  }
}

module.exports = {
  listShops,
  getShop,
};
