const shopService = require('../../services/customer/shop.service');
const productService = require('../../services/customer/product.service');
 
// ── Shared row → JSON mapper ────────────────────────────────────────────
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
// → Returns a single shop
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
 
// GET /api/customer/shops/:id/products
// → Returns products for a specific shop
async function getShopProducts(req, res) {
  try {
    const shopId = Number(req.params.id);
    const products = await productService.findPublicProductsByShop(shopId);
   
    // Using simple mapping to match your product service output
    const mappedProducts = products.map(row => ({
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
    }));
 
    res.json({ success: true, data: mappedProducts });
  } catch (err) {
    console.error('[customer getShopProducts]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch shop products' });
  }
}
 
module.exports = {
  listShops,
  getShop,
  getShopProducts
};