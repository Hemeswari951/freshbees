// backend/controllers/customer/wishlist.controller.js
const wishlistService = require('../../services/customer/wishlist.service');
const productService = require('../../services/customer/product.service');

// ── Row → JSON matching Flutter ProductModel.fromJson() ────────────────────
// Same shape as controllers/customer/product.controller.js:mapListItem, so
// wishlist items render with the exact same ProductCard used everywhere
// else in the app. Now also includes subCategory, rating, and reviewCount
// (previously missing here, so wishlist cards always showed a blank
// sub-category and a 0 rating with no count regardless of the real data).
function mapListItem(row) {
  return {
    id: row.product_id,
    productName: row.product_name,
    description: row.description || '',
    price: Number(row.price),
    mrp: row.mrp != null ? Number(row.mrp) : null,
    discountPercent: Number(row.discount_percent) || 0,
    thumbnail: row.thumbnail || '',
    shopId: row.shop_id,
    shopName: row.shop_name,
    categoryId: row.category_id,
    categoryName: row.category_name || '',
    subCategory: row.sub_category || '',
    brandName: row.brand_name || '',
    totalStock: Number(row.total_stock) || 0,
    stockStatus: productService.stockStatus(row.total_stock),
    rating: row.rating != null ? Number(row.rating) : 0,
    reviewCount: Number(row.review_count) || 0,
  };
}

// GET /api/customer/wishlist
// → Every product the logged-in customer has wishlisted.
async function listWishlist(req, res) {
  try {
    // customerauth middleware sets req.customer.customerId (camelCase) —
    // NOT customer_id. Using the wrong key here silently produced
    // `undefined`, which matched zero rows on every query.
    const rows = await wishlistService.getWishlistProducts(req.customer.customerId);
    res.json({ success: true, data: rows.map(mapListItem) });
  } catch (err) {
    console.error('[customer listWishlist]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch wishlist' });
  }
}

// POST /api/customer/wishlist/:productId
// → Add a product to the wishlist (heart tap on a product card).
async function addToWishlist(req, res) {
  try {
    const productId = Number(req.params.productId);
    await wishlistService.addToWishlist(req.customer.customerId, productId);
    res.json({ success: true, message: 'Added to wishlist' });
  } catch (err) {
    console.error('[customer addToWishlist]', err);
    res.status(500).json({ success: false, message: 'Failed to add to wishlist' });
  }
}

// DELETE /api/customer/wishlist/:productId
// → Remove a product from the wishlist (heart tap again).
async function removeFromWishlist(req, res) {
  try {
    const productId = Number(req.params.productId);
    await wishlistService.removeFromWishlist(req.customer.customerId, productId);
    res.json({ success: true, message: 'Removed from wishlist' });
  } catch (err) {
    console.error('[customer removeFromWishlist]', err);
    res.status(500).json({ success: false, message: 'Failed to remove from wishlist' });
  }
}

module.exports = {
  listWishlist,
  addToWishlist,
  removeFromWishlist,
};