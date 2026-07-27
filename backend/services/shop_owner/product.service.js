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
    sub_category: row.sub_category,
    brand: row.brand_name || '—',
    price: Number(row.price),
    mrp: row.mrp != null ? Number(row.mrp) : null,
    discountPercent: Number(row.discount_percent),
    stock,
    stockStatus: stockStatus(stock),
    status: row.is_active ? 'Active' : 'Inactive',
    thumbnail: row.thumbnail,
    // NEW — per-variant flags, independent of the total stock number.
    // Even if total stock across all variants is healthy, one variant
    // being 0 (or under 5) still needs to be surfaced on the card.
    hasOutOfStockVariant: row.has_out_of_stock === true,
    hasLowStockVariant: row.has_low_stock === true,
  };
}

// Shape consumed by ProductViewScreen (Flutter) — full detail with
// colors -> images/variants, matching exactly what _ProductViewScreenState
// reads (product['colors'][i]['images'][j]['url'/'type'],
// product['colors'][i]['variants'][j]['id'/'size'/'stock'], etc.)
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
        // Raw per-variant override — null means "no override, uses the
        // product's base price/mrp". The edit screen needs this (not just
        // effectivePrice/effectiveMrp below) to know whether to show this
        // size's price fields as blank vs. filled in — effectivePrice is
        // COALESCEd against the product price, so it always has a value
        // and can't be used to tell "real override" apart from "fallback".
        price: v.price != null ? Number(v.price) : null,
        mrp: v.mrp != null ? Number(v.mrp) : null,
        effectivePrice: v.effective_price != null ? Number(v.effective_price) : null,
        effectiveMrp: v.effective_mrp != null ? Number(v.effective_mrp) : null,
        variantDiscountPercent: Number(v.discount_percent),
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
    categoryId: row.category_id,
    brand: row.brand_name || '—',
    brandId: row.brand_id,
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
    discountPercent: Number(row.discount_percent),
    status: row.is_active ? 'Active' : 'Inactive',
    totalStock,
    stockStatus: stockStatus(totalStock),
    colors,
    tags: row.tags || [],
    attributes: row.attributes || [],
  };
}

async function getAllProducts(shopId) {
  const rows = await productModel.findAllProducts(shopId);
  return rows.map(toListItem);
}

async function getProductById(productId, shopId) {
  const row = await productModel.findProductById(productId, shopId);
  if (!row) return null;
  return toDetail(row);
}

// payload: {
//   productName, description, categoryId, brandId, mrp, price,
//   subCategory, fabric, pattern, fitType, sleeveType, neckType, occasion,
//   washCare, countryOfOrigin,
//   colors: [{
//     colorName, colorHex,
//     images: [{ url, type }],           // type: front | back | side | zoom | 360
//     sizes: [{ size, stockQuantity, price, mrp }],
//   }],
//   tags: string[],
//   attributes: [{ label, value }],
// }
//
// Orchestrates everything that needs to happen when a shop owner adds a
// new product: the product row itself, its SKU (backend-generated, never
// typed by the owner), its colors + images + size/stock variants, its
// tags, and its category-specific extra attributes. Returns the SAME
// shape as getProductById (toDetail) so AddProductScreen's `created['id']`
// works and can navigate straight into ProductViewScreen with it.
async function createProductForShop(shopId, payload) {
  const product = await productModel.create(shopId, payload);

  // SKU can only be built once we have a product_id (format:
  // SKU-SHOP<shopId>-PROD<productId>), so this happens right after
  // create(), before anything else touches the product.
  await productModel.generateAndSetSku(product.product_id, shopId);

  for (const color of payload.colors || []) {
    const savedColor = await productModel.addColor(product.product_id, color);
    if (color.images?.length) {
      await productModel.addColorImages(product.product_id, savedColor.product_color_id, color.images);
    }
    if (color.sizes?.length) {
      // NOTE: colorName is no longer passed here — product_variants has
      // no `color` column anymore (it duplicated product_colors.color_name).
      // Color now comes ONLY through product_color_id.
      await productModel.addColorVariants(
        product.product_id,
        savedColor.product_color_id,
        color.sizes
      );
    }
  }

  // tags[] -> resolves/creates rows in `tags`, maps them in `product_tags`
  if (payload.tags?.length) {
    await productModel.addProductTags(product.product_id, payload.tags);
  }

  // attributes[] -> category-specific extras into `product_attributes` (EAV)
  if (payload.attributes?.length) {
    await productModel.addProductAttributes(product.product_id, payload.attributes);
  }

  return getProductById(product.product_id, shopId);
}

async function updateForShop(productId, shopId, payload) {
  const product = await productModel.updateByShop(productId, shopId, payload);
  if (!product) return null;

  // Existing colors on this product, WITH their current images/variants —
  // needed to diff against the incoming payload.
  const existingColors = await productModel.findColorsWithDetailByProduct(productId);
  const existingColorIds = new Set(existingColors.map((c) => c.product_color_id));
  const payloadColorIds = new Set(
    (payload.colors || []).filter((c) => c.colorId).map((c) => c.colorId)
  );

  // 1) Colors removed entirely (present in DB, missing from payload) —
  //    delete their images from STORAGE first, then delete DB rows.
  for (const existing of existingColors) {
    if (!payloadColorIds.has(existing.product_color_id)) {
      await productModel.deleteImagesFromStorageAndDb(existing.images);
      await productModel.deleteColor(existing.product_color_id); // cascades variants
    }
  }

  // 2) Walk each color in the payload — update or insert.
  for (const color of payload.colors || []) {
    let productColorId = color.colorId;

    if (productColorId) {
      // ── Existing color: update name/hex ──
      await productModel.updateColor(productColorId, color.colorName, color.colorHex);

      const existing = existingColors.find((c) => c.product_color_id === productColorId);
      const oldImages = existing ? existing.images : [];

      // existingImages = { front: url|null, back: url|null, ... } sent from Flutter.
      // Any angle where existingImages[angle] is null/missing AND no new
      // file was uploaded for that angle = the owner removed that photo.
      const keptFixedUrls = Object.values(color.existingImages || {}).filter(Boolean);
      const keptSpinUrls = color.existingSpin360 || [];
      const keptUrls = new Set([...keptFixedUrls, ...keptSpinUrls]);

      // Old images NOT in the kept set = replaced or removed → delete
      // from storage + DB.
      const toDelete = oldImages.filter((img) => !keptUrls.has(img.image_url));
      if (toDelete.length) {
        await productModel.deleteImagesFromStorageAndDb(toDelete);
      }

      // Add newly uploaded angle photos + newly uploaded 360 frames.
      // display_order continues after however many images are being kept,
      // so 360 frames still play back after front/back/side/zoom.
      const newImages = [...(color.newImages || []), ...(color.newSpin || [])];
      if (newImages.length) {
        const keptCount = keptUrls.size;
        await productModel.addColorImages(productId, productColorId, newImages, keptCount);
      }

      // ── Sizes: update existing variants, insert new ones, delete removed ──
      const payloadVariantIds = new Set(
        (color.sizes || []).filter((s) => s.variantId).map((s) => s.variantId)
      );
      const existingVariantIds = existing ? existing.variants.map((v) => v.variant_id) : [];
      const removedVariantIds = existingVariantIds.filter((id) => !payloadVariantIds.has(id));
      if (removedVariantIds.length) {
        await productModel.deleteVariantsByIds(removedVariantIds);
      }

      for (const size of color.sizes || []) {
        if (size.variantId) {
          await productModel.updateVariant(size.variantId, size);
        } else {
          await productModel.addColorVariants(productId, productColorId, [size]);
        }
      }
    } else {
      // ── Brand-new color added during edit ──
      const savedColor = await productModel.addColor(productId, color);
      const newImages = [...(color.newImages || []), ...(color.newSpin || [])];
      if (newImages.length) {
        await productModel.addColorImages(productId, savedColor.product_color_id, newImages, 0);
      }
      if (color.sizes?.length) {
        await productModel.addColorVariants(productId, savedColor.product_color_id, color.sizes);
      }
    }
  }

  // Tags/attributes: full replace every time (matches Flutter comment).
  await productModel.replaceProductTags(productId, payload.tags || []);
  await productModel.replaceProductAttributes(productId, payload.attributes || []);

  return getProductById(productId, shopId);
}


async function setActiveForShop(productId, shopId, isActive) {
  const product = await productModel.setActiveByShop(productId, shopId, isActive);
  if (!product) return null;
  return getProductById(productId, shopId);
}

async function deleteForShop(productId, shopId) {
  return productModel.deleteByShop(productId, shopId);
}

// Owner "Manage stock" screen. delta can be positive (restock) or negative
// (manual correction / damage write-off) — it never creates a new product
// or a new variant, only adjusts the number on an existing one.
//
// Returns the shape ProductViewScreen._openStockEditor expects after
// calling ProductService.adjustVariantStock — just the raw updated
// variant row (variant_id, product_id, product_color_id, size,
// stock_quantity, price, mrp). Flutter re-fetches the full product via
// _load() right after this call anyway, so this doesn't need reshaping.
async function adjustStockForShop(variantId, shopId, delta) {
  return productModel.adjustVariantStock(variantId, shopId, delta);
}

module.exports = {
  getAllProducts,
  getProductById,
  createProductForShop,
  updateForShop,
  setActiveForShop,
  deleteForShop,
  adjustStockForShop,
};