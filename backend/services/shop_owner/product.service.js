const productModel = require('../../models/shop_owner/product.model');

const LOW_STOCK_THRESHOLD = 5;

function stockStatus(totalStock) {
  if (totalStock <= 0) return 'Out of stock';
  if (totalStock <= LOW_STOCK_THRESHOLD) return 'Only few left';
  return 'In stock';
}

// Shape consumed by ProductsScreen's grid cards (Flutter).
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
    // Per-variant flags, independent of total stock — even if the total
    // across all variants looks healthy, ONE variant hitting 0 (or
    // dropping under 5) still needs to be surfaced on the product card.
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
// shape as getOneForShop (toDetail) so AddProductScreen's `created['id']`
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

  return getOneForShop(product.product_id, shopId);
}

// ── EDIT flow ──────────────────────────────────────────────────────────
//
// payload.colors[] here (as built by products.controller.js#updateProduct)
// looks like:
//   {
//     colorId: 3 | null,           // null = brand-new color
//     colorName, colorHex,
//     existingImages: { front: url|null, back: url|null, ... },  // KEPT angle photos
//     existingSpin360: [url, ...],                                // KEPT 360 photos
//     newImages: [{ url, type }],   // freshly uploaded angle photos this request
//     newSpin: [{ url, type: '360' }], // freshly uploaded 360 frames this request
//     sizes: [{ variantId: 7 | null, size, stockQuantity, price, mrp }],
//   }
//
// ⚠️ CLIENT CONTRACT for a clean replace: when the owner picks a NEW photo
// for an angle that already had one, the client MUST send that angle as
// `null` in `existingImages` (not omit it, not leave the old URL in
// there) — otherwise this diff below sees the old URL as "still kept"
// and you end up with BOTH the old and the new photo saved for the same
// angle. (Flutter AddProductScreen._pickAngleImage does this correctly —
// it clears existingImageUrls[angle] the moment a replacement is picked.)
//
// Diffing logic:
//  1. Colors that exist in DB but are missing from payload entirely →
//     the owner removed that whole color. Delete its images from
//     STORAGE first, then its variants, then the color row.
//  2. For each color still present:
//     - update name/hex
//     - build the "kept" URL set from existingImages + existingSpin360
//     - any OLD image whose URL isn't in that kept set was either
//       replaced (new file uploaded for that angle) or removed by the
//       owner → delete it from storage + DB
//     - insert newImages/newSpin as new rows, continuing display_order
//       after however many are being kept
//     - variants: update ones with a variantId, insert ones without,
//       delete any old variant whose id isn't in the payload anymore
//  3. Colors with no colorId are brand-new — just insert them.
//  4. Tags/attributes are a full replace every time (edit form always
//     sends the complete current list, not a diff).
async function updateForShop(productId, shopId, payload) {
  const product = await productModel.updateByShop(productId, shopId, payload);
  if (!product) return null;

  const existingColors = await productModel.findColorsWithDetailByProduct(productId);
  const payloadColorIds = new Set(
    (payload.colors || []).filter((c) => c.colorId).map((c) => c.colorId)
  );

  // 1) Colors removed entirely.
  for (const existing of existingColors) {
    if (!payloadColorIds.has(existing.product_color_id)) {
      await productModel.deleteImagesFromStorageAndDb(existing.images);
      await productModel.deleteColor(existing.product_color_id); // variants first, then color
    }
  }

  // 2) Walk each color in the payload — update existing or insert new.
  for (const color of payload.colors || []) {
    if (color.colorId) {
      // ── Existing color ──
      await productModel.updateColor(color.colorId, color.colorName, color.colorHex);

      const existing = existingColors.find((c) => c.product_color_id === color.colorId);
      const oldImages = existing ? existing.images : [];

      const keptFixedUrls = Object.values(color.existingImages || {}).filter(Boolean);
      const keptSpinUrls = color.existingSpin360 || [];
      const keptUrls = new Set([...keptFixedUrls, ...keptSpinUrls]);

      // Old images not in the kept set = replaced or removed → delete.
      const toDelete = oldImages.filter((img) => !keptUrls.has(img.image_url));
      if (toDelete.length) {
        await productModel.deleteImagesFromStorageAndDb(toDelete);
      }

      // Newly uploaded angle photos + 360 frames get appended after
      // whatever's being kept, so spin order/display order stays correct.
      const newImages = [...(color.newImages || []), ...(color.newSpin || [])];
      if (newImages.length) {
        await productModel.addColorImages(productId, color.colorId, newImages, keptUrls.size);
      }

      // ── Sizes: update / insert / delete ──
      const payloadVariantIds = new Set(
        (color.sizes || []).filter((s) => s.variantId).map((s) => s.variantId)
      );
      const existingVariantIds = existing ? existing.variants.map((v) => v.variant_id) : [];
      const removedVariantIds = existingVariantIds.filter((vid) => !payloadVariantIds.has(vid));
      if (removedVariantIds.length) {
        await productModel.deleteVariantsByIds(removedVariantIds);
      }

      for (const size of color.sizes || []) {
        if (size.variantId) {
          await productModel.updateVariant(size.variantId, size);
        } else {
          await productModel.addColorVariants(productId, color.colorId, [size]);
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

  // Tags/attributes: full replace every time.
  await productModel.replaceProductTags(productId, payload.tags || []);
  await productModel.replaceProductAttributes(productId, payload.attributes || []);

  return getOneForShop(productId, shopId);
}

async function setActiveForShop(productId, shopId, isActive) {
  const product = await productModel.setActiveByShop(productId, shopId, isActive);
  if (!product) return null;
  return getOneForShop(productId, shopId);
}

// ── DELETE flow ──────────────────────────────────────────────────────
//
// Deleting a product now cleans up EVERYTHING that belongs to it, not
// just the `products` row:
//   1. every image FILE in storage (all colors, all angles + 360 frames)
//   2. every product_images DB row (done as part of step 1, via the same
//      helper the edit flow uses)
//   3. every variant + color row
//   4. tags + attributes
//   5. the product row itself
//
// Steps 3-4 are done explicitly here rather than relying on an FK
// ON DELETE CASCADE — this way the cleanup is correct regardless of how
// (or whether) cascades are set up in the schema; if cascades ARE
// configured, these calls just delete 0 already-gone rows, which is
// harmless.
async function deleteForShop(productId, shopId) {
  const row = await productModel.findByIdAndShop(productId, shopId);
  if (!row) return null; // not found, or belongs to a different shop — nothing to clean up

  // 1) + 2) Storage files + product_images rows, across every color.
  const allImages = row.colors.flatMap((c) => c.images);
  await productModel.deleteImagesFromStorageAndDb(allImages);

  // 3) Variants + color rows.
  for (const color of row.colors) {
    await productModel.deleteColor(color.product_color_id);
  }

  // 4) Tags + attributes — replace with an empty list = full clear.
  await productModel.replaceProductTags(productId, []);
  await productModel.replaceProductAttributes(productId, []);

  // 5) The product row itself.
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
  getAllForShop,
  getOneForShop,
  createProductForShop,
  updateForShop,
  setActiveForShop,
  deleteForShop,
  adjustStockForShop,
};