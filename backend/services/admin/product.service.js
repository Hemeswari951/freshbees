const productModel = require('../../models/admin/product.model');

function mapProductListItem(row) {
  return {
    productId: row.product_id,
    productName: row.product_name,
    sku: row.sku,
    subCategory: row.sub_category,
    categoryName: row.category_name,
    brandName: row.brand_name,
    mrp: Number(row.mrp),
    price: Number(row.price),
    discountPercent: Number(row.discount_percent),
    isActive: row.is_active,
    createdAt: row.created_at,
    shopId: row.shop_id,
    shopName: row.shop_name,
    ownerName: row.owner_name,
    // "image" so it matches the key ProductsScreen already reads
    // (p['image']) — keep in sync if that screen's key ever changes.
    image: row.thumbnail,
    stock: Number(row.total_stock),
    hasOutOfStock: row.has_out_of_stock,
    hasLowStock: row.has_low_stock,
  };
}

// Full product detail. Matches what ProductViewScreen reads: name,
// subCategory, price, mrp, discountPercent, isActive, colors (each with
// images[{type,url}] and variants[{size,stock,effectivePrice,
// effectiveMrp,variantDiscountPercent}]), tags, attributes, and the flat
// specification fields (fabric, pattern, fitType, ...).
function mapProductDetail(product) {
  return {
    productId: product.product_id,
    name: product.product_name,
    sku: product.sku,
    description: product.description,
    subCategory: product.sub_category,
    categoryName: product.category_name,
    brand: product.brand_name,
    fabric: product.fabric,
    pattern: product.pattern,
    fitType: product.fit_type,
    sleeveType: product.sleeve_type,
    neckType: product.neck_type,
    occasion: product.occasion,
    washCare: product.wash_care,
    countryOfOrigin: product.country_of_origin,
    mrp: Number(product.mrp),
    price: Number(product.price),
    discountPercent: Number(product.discount_percent),
    isActive: product.is_active,
    createdAt: product.created_at,
    updatedAt: product.updated_at,
    shopId: product.shop_id,
    shopName: product.shop_name,
    ownerName: product.owner_name,
    colors: (product.colors || []).map((c) => ({
      colorId: c.product_color_id,
      colorName: c.color_name,
      colorHex: c.color_hex,
      images: (c.images || []).map((i) => ({
        imageId: i.image_id,
        url: i.image_url,
        type: i.image_type,
        order: i.display_order,
      })),
      variants: (c.variants || []).map((v) => ({
        variantId: v.variant_id,
        size: v.size,
        stock: v.stock_quantity,
        price: Number(v.price),
        mrp: Number(v.mrp),
        effectivePrice: Number(v.effective_price),
        effectiveMrp: Number(v.effective_mrp),
        variantDiscountPercent: Number(v.discount_percent),
      })),
    })),
    tags: product.tags || [],
    attributes: product.attributes || [],
  };
}

// filters: { shopId?, categoryId?, isActive?, search? } — all optional,
// passed straight through to the model to narrow the WHERE clause.
async function getAllProducts(filters) {
  const rows = await productModel.findAllProductsAdmin(filters);
  return rows.map(mapProductListItem);
}

// Returns null if not found — controller turns that into a 404.
async function getProductById(productId) {
  const product = await productModel.findProductByIdAdmin(productId);
  if (!product) return null;
  return mapProductDetail(product);
}



module.exports = {
  getAllProducts,
  getProductById,
};