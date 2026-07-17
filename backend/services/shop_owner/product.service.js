const productModel = require('../../models/shop_owner/product.model');

const LOW_STOCK_THRESHOLD = 5;

function stockStatus(totalStock) {
  if (totalStock <= 0) return 'Out of stock';
  if (totalStock <= LOW_STOCK_THRESHOLD) return 'Only few left';
  return 'In stock';
}

function toListItem(row) {
  const stock = Number(row.total_stock);
  return {
    id: row.product_id,
    name: row.product_name,
    category: row.category_name || 'Uncategorized',
    brand: row.brand_name || '—',
    price: Number(row.price),
    mrp: row.mrp != null ? Number(row.mrp) : null,
    discountPercent: row.discount_percent,
    stock,
    stockStatus: stockStatus(stock),
    status: row.is_active ? 'Active' : 'Inactive',
    thumbnail: row.thumbnail,
  };
}

function toDetail(row) {
  const colors = row.colors.map((c) => {
    const colorStock = c.variants.reduce((sum, v) => sum + Number(v.stock_quantity), 0);
    return {
      id: c.product_color_id,
      colorName: c.color_name,
      colorHex: c.color_hex,
      images: c.images.map((i) => ({ id: i.image_id, url: i.image_url, type: i.image_type })),
      variants: c.variants.map((v) => ({
        id: v.variant_id,
        size: v.size,
        stock: v.stock_quantity,
        status: stockStatus(v.stock_quantity),
      })),
      colorStock,
      colorStockStatus: stockStatus(colorStock),
    };
  });
  const totalStock = colors.reduce((sum, c) => sum + c.colorStock, 0);

  return {
    id: row.product_id,
    name: row.product_name,
    description: row.description,
    category: row.category_name || 'Uncategorized',
    brand: row.brand_name || '—',
    price: Number(row.price),
    mrp: row.mrp != null ? Number(row.mrp) : null,
    discountPercent: row.discount_percent,
    status: row.is_active ? 'Active' : 'Inactive',
    totalStock,
    stockStatus: stockStatus(totalStock),
    colors,
  };
}

async function getAllForShop(shopId) {
  const rows = await productModel.findAllByShop(shopId);
  return rows.map(toListItem);
}

async function getOneForShop(productId, shopId) {
  const row = await productModel.findByIdAndShop(productId, shopId);
  if (!row) return null;
  return toDetail(row);
}

// payload: {
//   productName, description, categoryId, brandId, mrp, price, discountPercent,
//   colors: [{
//     colorName, colorHex,
//     images: [{ url, type }],           // type: front | back | side | zoom
//     sizes: [{ size, stockQuantity }],
//   }]
// }
async function createForShop(shopId, payload) {
  const product = await productModel.create(shopId, payload);

  for (const color of payload.colors || []) {
    const savedColor = await productModel.addColor(product.product_id, color);
    if (color.images?.length) {
      await productModel.addColorImages(product.product_id, savedColor.product_color_id, color.images);
    }
    if (color.sizes?.length) {
      await productModel.addColorVariants(
        product.product_id,
        savedColor.product_color_id,
        color.colorName,
        color.sizes
      );
    }
  }

  return getOneForShop(product.product_id, shopId);
}

async function updateForShop(productId, shopId, payload) {
  const product = await productModel.updateByShop(productId, shopId, payload);
  if (!product) return null;
  return getOneForShop(productId, shopId);
}

async function setActiveForShop(productId, shopId, isActive) {
  const product = await productModel.setActiveByShop(productId, shopId, isActive);
  if (!product) return null;
  return getOneForShop(productId, shopId);
}

async function deleteForShop(productId, shopId) {
  return productModel.deleteByShop(productId, shopId);
}

// Owner "Manage stock" screen. delta can be positive (restock) or negative
// (manual correction / damage write-off) — it never creates a new product
// or a new variant, only adjusts the number on an existing one.
async function adjustStockForShop(variantId, shopId, delta) {
  return productModel.adjustVariantStock(variantId, shopId, delta);
}

module.exports = {
  getAllForShop,
  getOneForShop,
  createForShop,
  updateForShop,
  setActiveForShop,
  deleteForShop,
  adjustStockForShop,
};