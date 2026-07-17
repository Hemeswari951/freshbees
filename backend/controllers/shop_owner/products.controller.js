const productService = require('../../services/shop_owner/product.service');
const categoryModel = require('../../models/shared/category.model');
const brandModel = require('../../models/shared/brand.model');
const { uploadFile } = require('../../config/storageClient');

const { FIELD_NAME_RE, SPIN_FIELD_NAME_RE } = require('../../middleware/upload');

async function getMeta(req, res) {
  try {
    const [categories, brands] = await Promise.all([
      categoryModel.findAll(),
      brandModel.findAll(),
    ]);
    res.json({ success: true, data: { categories, brands } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to load categories/brands' });
  }
}

// GET /api/shop/products  (shopId comes from the logged-in owner's JWT, NOT the URL)
async function getAllProducts(req, res) {
  try {
    const products = await productService.getAllForShop(req.shopOwner.shopId);
    res.json({ success: true, data: products });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to fetch products' });
  }
}

// GET /api/shop/products/:id
async function getProductById(req, res) {
  try {
    const id = Number(req.params.id);
    const product = await productService.getOneForShop(id, req.shopOwner.shopId);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, data: product });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to fetch product' });
  }
}

// POST /api/shop/products  (multipart/form-data — see uploadProductImages middleware)
//
// Text fields:
//   productName, description, categoryId, brandId, mrp, price, discountPercent
//   colors  -> JSON string, e.g.
//     '[{"colorName":"Brown","colorHex":"#5C3A2E",
//        "sizes":[{"size":"S","stockQuantity":3},{"size":"M","stockQuantity":2}]}]'
//   (images are NOT listed inside colors — they come in as files, see below)
//
// Files (field name encodes which color + which angle):
//   color_0_front, color_0_back, color_0_side, color_0_zoom  -> first color's photos
//   color_1_front, color_1_back, ...                          -> second color's photos
//   Any subset is fine — a color doesn't need all 4 angles.
//   color_0_360_0, color_0_360_1, ...                          -> first color's
//     real 360° turntable sequence, field suffix = frame/playback order.
//     Optional; 8-30 frames recommended for a smooth spin.
async function createProduct(req, res) {
  try {
    const b = req.body;
    if (!b.productName || !b.price) {
      return res.status(400).json({ success: false, message: 'productName and price are required' });
    }

    let colors = [];
    if (b.colors) {
      try {
        colors = JSON.parse(b.colors);
      } catch {
        return res.status(400).json({ success: false, message: 'colors must be valid JSON' });
      }
    }
    if (!colors.length) {
      return res.status(400).json({ success: false, message: 'At least one color is required' });
    }

    // Map each uploaded file back onto colors[index].images using its
    // fieldname (color_<index>_<type>, or color_<index>_360_<frame> for
    // the real 360° spin sequence). Files that don't belong to any color
    // index sent in `colors` are rejected — this stops a client bug (or a
    // tampered request) from silently attaching photos to nothing.
    const shopId = req.shopOwner.shopId;
    for (const color of colors) color.images = [];

    // Spin frames are collected per color here first (with their frame
    // index), THEN sorted and appended — multipart field order SHOULD
    // already match upload order, but sorting explicitly means the spin
    // sequence can never play back scrambled even if that ever isn't true.
    const spinByColor = {};

    for (const file of req.files || []) {
      const spinMatch = SPIN_FIELD_NAME_RE.exec(file.fieldname);
      if (spinMatch) {
        const colorIndex = Number(spinMatch[1]);
        const frameIndex = Number(spinMatch[2]);
        if (!colors[colorIndex]) {
          return res.status(400).json({
            success: false,
            message: `Received a 360° photo for color index ${colorIndex}, but colors[] only has ${colors.length} entries`,
          });
        }
        const filename = `${Date.now()}_${colorIndex}_360_${frameIndex}`;
        const url = await uploadFile(file, `products/${shopId}`, filename);

        (spinByColor[colorIndex] ??= []).push({ url, frameIndex });
        continue;
      }

      const match = FIELD_NAME_RE.exec(file.fieldname);
      if (!match) continue; // already rejected by multer's fileFilter, but guard anyway
      const colorIndex = Number(match[1]);
      const type = match[2];
      if (!colors[colorIndex]) {
        return res.status(400).json({
          success: false,
          message: `Received an image for color index ${colorIndex}, but colors[] only has ${colors.length} entries`,
        });
      }

      const filename = `${Date.now()}_${colorIndex}_${type}`;
      const url = await uploadFile(file, `products/${shopId}`, filename);

      colors[colorIndex].images.push({ url, type });
    }

    // Append each color's spin frames, in frame order, AFTER its
    // front/back/side/zoom photos — addColorImages() below assigns
    // display_order by array position, so this ordering is what the
    // customer-facing 360 viewer will actually play back.
    for (const [colorIndex, frames] of Object.entries(spinByColor)) {
      frames.sort((a, b) => a.frameIndex - b.frameIndex);
      for (const f of frames) {
        colors[colorIndex].images.push({ url: f.url, type: '360' });
      }
    }

    for (let i = 0; i < colors.length; i++) {
      if (!colors[i].images.length) {
        return res.status(400).json({ success: false, message: `Color "${colors[i].colorName}" has no photos` });
      }
    }

    const payload = {
      productName: b.productName,
      description: b.description,
      categoryId: b.categoryId ? Number(b.categoryId) : null,
      brandId: b.brandId ? Number(b.brandId) : null,
      mrp: b.mrp ? Number(b.mrp) : null,
      price: Number(b.price),
      discountPercent: b.discountPercent ? Number(b.discountPercent) : 0,
      colors,
    };

    const product = await productService.createForShop(shopId, payload);
    res.status(201).json({ success: true, data: product });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to create product' });
  }
}

// PUT /api/shop/products/:id
async function updateProduct(req, res) {
  try {
    const id = Number(req.params.id);
    const product = await productService.updateForShop(id, req.shopOwner.shopId, req.body);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, data: product });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to update product' });
  }
}

// PATCH /api/shop/products/:id/status  body: { status: "Active" | "Inactive" }
async function updateProductStatus(req, res) {
  try {
    const id = Number(req.params.id);
    const { status } = req.body;
    if (!['Active', 'Inactive'].includes(status)) {
      return res.status(400).json({ success: false, message: "status must be 'Active' or 'Inactive'" });
    }
    const product = await productService.setActiveForShop(id, req.shopOwner.shopId, status === 'Active');
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, data: product });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to update status' });
  }
}

// PATCH /api/shop/products/variants/:variantId/stock  body: { delta: 5 } or { delta: -2 }
// This is the "Manage stock" screen endpoint — restock (positive delta) or
// manual correction (negative delta). Never creates a new product/variant.
async function adjustStock(req, res) {
  try {
    const variantId = Number(req.params.variantId);
    const delta = Number(req.body.delta);
    if (!Number.isFinite(delta) || delta === 0) {
      return res.status(400).json({ success: false, message: 'delta must be a non-zero number' });
    }
    const variant = await productService.adjustStockForShop(variantId, req.shopOwner.shopId, delta);
    if (!variant) return res.status(404).json({ success: false, message: 'Variant not found' });
    res.json({ success: true, data: variant });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to adjust stock' });
  }
}

// DELETE /api/shop/products/:id
async function deleteProduct(req, res) {
  try {
    const id = Number(req.params.id);
    const deleted = await productService.deleteForShop(id, req.shopOwner.shopId);
    if (!deleted) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, message: 'Product deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to delete product' });
  }
}

module.exports = {
  getMeta,
  getAllProducts,
  getProductById,
  createProduct,
  updateProduct,
  updateProductStatus,
  adjustStock,
  deleteProduct,
};