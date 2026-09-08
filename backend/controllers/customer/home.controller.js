const homeService = require('../../services/customer/home.service');

/**
 * GET /shops
 * GET /shops?category=men
 *
 * Single route (Approach 2) — category is a query param, not baked
 * into the path. Adding a new category later (e.g. "Footwear") needs
 * zero backend code changes, as long as it exists in the `categories`
 * table and shops are linked to it via `shop_categories`.
 */

async function getShops(req, res) {
  try {
    const { category, latitude, longitude } = req.query;

    const lat = latitude !== undefined ? parseFloat(latitude) : undefined;
    const lng = longitude !== undefined ? parseFloat(longitude) : undefined;

    const shops = await homeService.getShops({
      category,
      latitude: Number.isFinite(lat) ? lat : undefined,
      longitude: Number.isFinite(lng) ? lng : undefined,
    });

    return res.status(200).json({ success: true, data: shops });
  } catch (err) {
    console.error('getShops error:', err);
    return res.status(500).json({ success: false, message: 'Could not fetch shops' });
  }
}

async function getShopDetail(req, res) {
  try {
    const { id } = req.params;
    const shop = await homeService.getShopDetails(id);

    if (!shop) {
      return res.status(404).json({ success: false, message: 'Shop not found' });
    }

    return res.status(200).json({ success: true, data: shop });
  } catch (err) {
    console.error('getShopDetail error:', err);
    return res.status(500).json({ success: false, message: 'Could not fetch shop details' });
  }
}

module.exports = { getShops, getShopDetail };