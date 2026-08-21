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
    const { category } = req.query;
    const shops = await homeService.getShops({ category });
    return res.status(200).json({ success: true, data: shops });
  } catch (err) {
    console.error('getShops error:', err);
    return res.status(500).json({ success: false, message: 'Could not fetch shops' });
  }
}

/**
 * GET /shops/:id
 * Not required for the Home tabs, but useful for a shop-detail fallback
 * fetch (same pattern the app already had before).
 */

module.exports = { getShops};