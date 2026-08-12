
const wishlistService = require('../../services/customer/wishlist.service');
const productService = require('../../services/customer/product.service');

// ── Row → JSON matching Flutter ProductModel.fromJson() ────────────────────
// Same shape as controllers/customer/product.controller.js:mapListItem, so
// wishlist items render with the exact same ProductCard used everywhere
// else in the app.
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
    brandName: row.brand_name || '',
    totalStock: Number(row.total_stock) || 0,
    stockStatus: productService.stockStatus(row.total_stock),
  };
}

// GET /api/customer/wishlist
// → Every product the logged-in customer has wishlisted.
async function listWishlist(req, res) {
  try {
    const rows = await wishlistService.getWishlistProducts(req.customer.customer_id);
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
    await wishlistService.addToWishlist(req.customer.customer_id, productId);
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
    await wishlistService.removeFromWishlist(req.customer.customer_id, productId);
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