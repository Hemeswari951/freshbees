const pool = require("../../config/db");

// Full cart for a customer, joined with product + variant details so the
// Cart screen can render everything (image, name, price, stock) in one call.
//
// FIX: the old query selected p.thumbnail and p.total_stock, but neither
// column exists on the `products` table (see thiraa_db.sql — images live
// in `product_images`, stock lives on `product_variants.stock_quantity`).
// That made every GET /api/customer/cart throw "column p.thumbnail does
// not exist", which cart.controller.js turned into the 500
// "Failed to fetch cart" the Bag screen was showing. Items were being
// added to cart_items fine — this SELECT just couldn't read them back.
exports.getCartByCustomer = async (customerId) => {
    const result = await pool.query(
        `SELECT
            ci.cart_item_id,
            ci.product_id,
            ci.variant_id,
            ci.quantity,
            p.product_name,
            img.image_url AS thumbnail,
            p.shop_id,
            COALESCE(pv.price, p.price) AS price,
            pv.stock_quantity AS stock_quantity,
            pv.size
         FROM cart_items ci
         JOIN products p ON p.product_id = ci.product_id
         LEFT JOIN product_variants pv ON pv.variant_id = ci.variant_id
         -- Pick one image for this row: prefer a photo tagged with the
         -- variant's own color, fall back to any photo of the product
         -- (e.g. when the item was added without a variant/color).
         LEFT JOIN LATERAL (
             SELECT pi.image_url
             FROM product_images pi
             WHERE pi.product_id = p.product_id
               AND (pv.product_color_id IS NULL OR pi.product_color_id = pv.product_color_id)
             ORDER BY pi.display_order ASC
             LIMIT 1
         ) img ON TRUE
         WHERE ci.customer_id = $1
         ORDER BY ci.created_at DESC`,
        [customerId]
    );
    return result.rows;
};

// Adds an item, or bumps the quantity if the same product+variant is
// already in the bag (so tapping "Add to Bag" twice just increases qty
// instead of creating a duplicate row).
exports.addToCart = async (customerId, productId, variantId, quantity) => {
    const existing = await pool.query(
        `SELECT cart_item_id, quantity FROM cart_items
         WHERE customer_id = $1 AND product_id = $2
           AND variant_id IS NOT DISTINCT FROM $3`,
        [customerId, productId, variantId || null]
    );

    if (existing.rows.length > 0) {
        const newQty = existing.rows[0].quantity + quantity;
        const updated = await pool.query(
            `UPDATE cart_items SET quantity = $1, updated_at = CURRENT_TIMESTAMP
             WHERE cart_item_id = $2 RETURNING cart_item_id`,
            [newQty, existing.rows[0].cart_item_id]
        );
        return updated.rows[0].cart_item_id;
    }

    const inserted = await pool.query(
        `INSERT INTO cart_items (customer_id, product_id, variant_id, quantity, created_at, updated_at)
         VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         RETURNING cart_item_id`,
        [customerId, productId, variantId || null, quantity]
    );
    return inserted.rows[0].cart_item_id;
};

exports.updateQuantity = async (customerId, cartItemId, quantity) => {
    const result = await pool.query(
        `UPDATE cart_items SET quantity = $1, updated_at = CURRENT_TIMESTAMP
         WHERE cart_item_id = $2 AND customer_id = $3
         RETURNING cart_item_id`,
        [quantity, cartItemId, customerId]
    );
    return result.rows[0] || null;
};

exports.removeCartItem = async (customerId, cartItemId) => {
    const result = await pool.query(
        `DELETE FROM cart_items WHERE cart_item_id = $1 AND customer_id = $2 RETURNING cart_item_id`,
        [cartItemId, customerId]
    );
    return result.rows[0] || null;
};

// Fetches specific cart rows (or the whole cart when no ids are passed)
// right before checkout, scoped to this customer.
exports.getCartItemsForCheckout = async (customerId, cartItemIds) => {
    if (cartItemIds && cartItemIds.length > 0) {
        const result = await pool.query(
            `SELECT cart_item_id, product_id, variant_id, quantity
             FROM cart_items
             WHERE customer_id = $1 AND cart_item_id = ANY($2::int[])`,
            [customerId, cartItemIds]
        );
        return result.rows;
    }

    const result = await pool.query(
        `SELECT cart_item_id, product_id, variant_id, quantity
         FROM cart_items WHERE customer_id = $1`,
        [customerId]
    );
    return result.rows;
};

exports.clearCartItems = async (customerId, cartItemIds) => {
    if (!cartItemIds || cartItemIds.length === 0) return;
    await pool.query(
        `DELETE FROM cart_items WHERE customer_id = $1 AND cart_item_id = ANY($2::int[])`,
        [customerId, cartItemIds]
    );
};
