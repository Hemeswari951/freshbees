const productService = require('../../services/admin/product.service');
const productModel = require('../../models/admin/product.model');

// GET /api/admin/products
// Query params (all optional): shopId, categoryId, isActive, search
async function getAllProducts(req, res) {
  try {
    const { shopId, categoryId, isActive, search } = req.query;

    const filters = {
      shopId: shopId ? Number(shopId) : undefined,
      categoryId: categoryId ? Number(categoryId) : undefined,
      // isActive arrives as the string "true"/"false" over query params —
      // convert explicitly, and leave undefined (no filter) if not sent.
      isActive:
        isActive === 'true' ? true : isActive === 'false' ? false : undefined,
      search: search || undefined,
    };

    const products = await productService.getAllProducts(filters);
    return res.status(200).json({ success: true, products });
  } catch (err) {
    console.error('getAllProducts (admin) error:', err);
    return res
      .status(500)
      .json({ success: false, message: 'Failed to load products' });
  }
}

// GET /api/admin/products/:productId
async function getProductById(req, res) {
  try {
    const productId = Number(req.params.productId);
    if (!Number.isInteger(productId)) {
      return res
        .status(400)
        .json({ success: false, message: 'Invalid product id' });
    }

    const product = await productService.getProductById(productId);
    if (!product) {
      return res
        .status(404)
        .json({ success: false, message: 'Product not found' });
    }

    return res.status(200).json({ success: true, product });
  } catch (err) {
    console.error('getProductById (admin) error:', err);
    return res
      .status(500)
      .json({ success: false, message: 'Failed to load product' });
  }
}


async function updateProductStatus(req, res) {
  try {
    const productId = Number(req.params.productId);
    const { isActive } = req.body;

    if (Number.isNaN(productId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid product id',
      });
    }

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isActive must be true or false',
      });
    }

    const updated = await productModel.updateProductStatus(
      productId,
      isActive,
    );

    if (!updated) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    res.json({
      success: true,
      message: `Product ${isActive ? 'activated' : 'deactivated'
        } successfully`,
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      success: false,
      message: 'Failed to update product status',
    });
  }
};

module.exports = {
  getAllProducts,
  getProductById,
  updateProductStatus,
};