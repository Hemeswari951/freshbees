const shopService = require('../../services/shop_owner/profile.service');

// GET /api/shop/profile
//
// Single call that gives the mobile Profile screen everything it needs:
// shop identity (name/owner/logo/banner) PLUS the three stat-card
// numbers (products, orders, rating) — all computed live from the DB,
// never cached/stored, so they're always accurate. All the actual
// query orchestration + shaping lives in shop.service.js — this
// controller is just req-in / res-out.
async function getProfile(req, res) {
  try {
    const shopId = req.shopOwner.shopId;

    const profile = await shopService.getProfileForShop(shopId);
    if (!profile) {
      return res.status(404).json({ success: false, message: 'Shop not found' });
    }

    res.json({ success: true, data: profile });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to load profile' });
  }
}

// PUT /api/shop/profile  (multipart/form-data)
//
// Text fields (all optional — only send what changed):
//   shopName, ownerName, shopDescription
// Files (optional, field names below):
//   logo    -> single image, becomes the round avatar shown when no
//              network image is set (screen falls back to the shop's
//              first letter when logoUrl is null)
//   banner  -> single image, the green header banner
async function updateProfile(req, res) {
  try {
    const shopId = req.shopOwner.shopId;
    // If your shopownerauth middleware also puts the owner's own id on
    // req.shopOwner (e.g. req.shopOwner.shopOwnerId), it flows through
    // to the service so the name update targets exactly that row
    // instead of "first owner for this shop".
    const shopOwnerId = req.shopOwner.shopOwnerId;

    const profile = await shopService.updateProfileForShop(shopId, {
      body: req.body,
      files: req.files,
      shopOwnerId,
    });

    if (!profile) {
      return res.status(404).json({ success: false, message: 'Shop not found' });
    }

    res.json({ success: true, data: profile });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to update profile' });
  }
}

// GET /api/shop/reviews?page=1&limit=20
//
// Powers the "Reviews and ratings" screen — the individual review list
// (reviewer name, rating, comment, which product, when). Separate from
// GET /profile, which only carries the SUMMARY (avgRating/reviewCount).
async function getReviews(req, res) {
  try {
    const shopId = req.shopOwner.shopId;
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 20;

    const { reviews, page: p, limit: l } = await shopService.getReviewsForShop(
      shopId,
      { page, limit }
    );

    res.json({ success: true, data: reviews, page: p, limit: l });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to load reviews' });
  }
}

module.exports = {
  getProfile,
  updateProfile,
  getReviews,
};