const productService = require('../../services/customer/product.service');

// ── List row → JSON matching Flutter ProductModel.fromJson() ──────────────
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

// ── Detail row → JSON matching Flutter ProductDetailsModel.fromJson() ─────
function mapDetail(row) {
  const colors = row.colors.map((c) => ({
    productColorId: c.product_color_id,
    colorName: c.color_name,
    colorHex: c.color_hex,
    images: c.images.map((i) => ({
      imageId: i.image_id,
      imageUrl: i.image_url,
      imageType: i.image_type,
    })),
    variants: c.variants.map((v) => ({
      variantId: v.variant_id,
      productColorId: v.product_color_id,
      price: v.price != null ? Number(v.price) : null,
      mrp: v.mrp != null ? Number(v.mrp) : null,
      size: v.size,
      stockQuantity: v.stock_quantity,
    })),
  }));

  // Same "front image of first color" rule the list/thumbnail uses.
  const firstColorImages = colors[0]?.images || [];
  const thumbnail =
    firstColorImages.find((i) => i.imageType === 'front')?.imageUrl ||
    firstColorImages[0]?.imageUrl ||
    null;

  return {
    id: row.product_id,
    productName: row.product_name,
    description: row.description || '',
    subCategory: row.sub_category,
    fabric: row.fabric,
    pattern: row.pattern,
    fitType: row.fit_type,
    sleeveType: row.sleeve_type,
    neckType: row.neck_type,
    occasion: row.occasion,
    washCare: row.wash_care,
    countryOfOrigin: row.country_of_origin,
    price: Number(row.price),
    mrp: row.mrp != null ? Number(row.mrp) : null,
    discountPercent: Number(row.discount_percent) || 0,
    thumbnail,
    shopId: row.shop_id,
    shopName: row.shop_name,
    categoryId: row.category_id,
    categoryName: row.category_name || '',
    brandName: row.brand_name || '',
    totalStock: Number(row.total_stock) || 0,
    stockStatus: productService.stockStatus(row.total_stock),
    colors,
    attributes: row.attributes.map((a) => ({
      attributeId: a.attribute_id,
      label: a.label,
      value: a.value,
      displayOrder: a.display_order,
    })),
    tags: row.tags.map((t) => ({
      tagId: t.tag_id,
      tagName: t.tag_name,
    })),
    reviews: row.reviews.map((r) => ({
      reviewId: r.review_id,
      customerId: r.customer_id,
      rating: r.rating,
      reviewText: r.review_text,
      createdAt: r.created_at,
    })),
  };
}

// GET /api/customer/products
// GET /api/customer/products?shopId=5
// GET /api/customer/products?search=tshirt
async function listProducts(req, res) {
  try {
    const { shopId, search } = req.query;

    let rows;
    if (search && search.trim() !== '') {
      rows = await productService.findPublicProductsBySearch(search.trim());
    } else if (shopId) {
      rows = await productService.findPublicProductsByShop(Number(shopId));
    } else {
      rows = await productService.findAllPublicProducts();
    }

    res.json({ success: true, data: rows.map(mapListItem) });
  } catch (err) {
    console.error('[customer listProducts]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch products' });
  }
}

// GET /api/customer/products/:id
async function getProduct(req, res) {
  try {
    const id = Number(req.params.id);
    const row = await productService.findPublicProductById(id);
    if (!row) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    res.json({ success: true, data: mapDetail(row) });
  } catch (err) {
    console.error('[customer getProduct]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch product' });
  }
}

module.exports = {
  listProducts,
  getProduct,
};
