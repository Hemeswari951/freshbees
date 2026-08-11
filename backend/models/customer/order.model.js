const pool = require("../../config/db");

// Adjust the column names below if yours differ.
exports.getProductForOrder = async (productId, variantId) => {
    const productResult = await pool.query(
        `SELECT product_id, shop_id, price AS product_price
         FROM products
         WHERE product_id = $1`,
        [productId]
    );

    if (productResult.rows.length === 0) {
        return null;
    }

    const product = productResult.rows[0];
    let price = product.product_price;

    if (variantId) {
        const variantResult = await pool.query(
            `SELECT variant_id, price AS variant_price, stock_quantity
             FROM product_variants
             WHERE variant_id = $1 AND product_id = $2`,
            [variantId, productId]
        );

        if (variantResult.rows.length === 0) {
            const err = new Error("Selected size is not available for this product");
            err.statusCode = 400;
            throw err;
        }

        const variant = variantResult.rows[0];

        if (variant.stock_quantity !== null && variant.stock_quantity <= 0) {
            const err = new Error("Selected size is out of stock");
            err.statusCode = 400;
            throw err;
        }

        if (variant.variant_price !== null && variant.variant_price !== undefined) {
            price = variant.variant_price;
        }
    }

    return { shopId: product.shop_id, price };
};

// Creates the order + order_items row for a single-product "Buy Now" from
// the product details screen (no cart, no address flow yet on that path).
exports.createOrder = async (customerId, productId, variantId, quantity, shopId, price) => {
    const totalAmount = price * quantity;

    const orderResult = await pool.query(
        `INSERT INTO orders (customer_id, total_amount, payment_method, created_at)
         VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
         RETURNING order_id`,
        [customerId, totalAmount, "COD"]
    );

    const orderId = orderResult.rows[0].order_id;

    const itemResult = await pool.query(
        `INSERT INTO order_items
            (order_id, shop_id, product_id, variant_id, quantity, price, item_status, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, 'Processing', CURRENT_TIMESTAMP)
         RETURNING order_item_id`,
        [orderId, shopId, productId, variantId || null, quantity, price]
    );

    return { orderId, orderItemId: itemResult.rows[0].order_item_id };
};

// Places a SINGLE order containing MULTIPLE items — used by "Buy Now" from
// the Cart screen, where the customer can be checking out several products
// (possibly from different shops) at once. Wrapped in a transaction so a
// failure on one item never leaves a half-created order behind.
//
// items: [{ productId, variantId, quantity, shopId, price }]
//
// UPDATED: now takes addressId + paymentMethod (chosen on the new Address
// and Payment screens) and actually stores them on the order — previously
// this hardcoded "COD" and left address_id NULL even though both columns
// already existed on `orders`.
//
// Payment status: since there's no real payment gateway wired up, COD is
// stored as "Pending" (collected on delivery) and any other method
// (UPI / Card / Netbanking) is stored as "Paid" — i.e. this is a demo
// checkout flow, not a real payment integration.
exports.createOrderFromItems = async (customerId, items, addressId, paymentMethod) => {
    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        const totalAmount = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
        const method = paymentMethod || "COD";
        const paymentStatus = method === "COD" ? "Pending" : "Paid";

        const orderResult = await client.query(
            `INSERT INTO orders (customer_id, address_id, total_amount, payment_method, payment_status, created_at)
             VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
             RETURNING order_id`,
            [customerId, addressId, totalAmount, method, paymentStatus]
        );
        const orderId = orderResult.rows[0].order_id;

        const orderItemIds = [];
        for (const item of items) {
            const itemResult = await client.query(
                `INSERT INTO order_items
                    (order_id, shop_id, product_id, variant_id, quantity, price, item_status, created_at)
                 VALUES ($1, $2, $3, $4, $5, $6, 'Processing', CURRENT_TIMESTAMP)
                 RETURNING order_item_id`,
                [orderId, item.shopId, item.productId, item.variantId || null, item.quantity, item.price]
            );
            orderItemIds.push(itemResult.rows[0].order_item_id);
        }

        await client.query("COMMIT");
        return { orderId, orderItemIds };
    } catch (err) {
        await client.query("ROLLBACK");
        throw err;
    } finally {
        client.release();
    }
};



/*const pool = require("../../config/db");

// Adjust the column names below if yours differ.
exports.getProductForOrder = async (productId, variantId) => {
    const productResult = await pool.query(
        `SELECT product_id, shop_id, price AS product_price
         FROM products
         WHERE product_id = $1`,
        [productId]
    );

    if (productResult.rows.length === 0) {
        return null;
    }

    const product = productResult.rows[0];
    let price = product.product_price;

    if (variantId) {
        const variantResult = await pool.query(
            `SELECT variant_id, price AS variant_price, stock_quantity
             FROM product_variants
             WHERE variant_id = $1 AND product_id = $2`,
            [variantId, productId]
        );

        if (variantResult.rows.length === 0) {
            const err = new Error("Selected size is not available for this product");
            err.statusCode = 400;
            throw err;
        }

        const variant = variantResult.rows[0];

        if (variant.stock_quantity !== null && variant.stock_quantity <= 0) {
            const err = new Error("Selected size is out of stock");
            err.statusCode = 400;
            throw err;
        }

        if (variant.variant_price !== null && variant.variant_price !== undefined) {
            price = variant.variant_price;
        }
    }

    return { shopId: product.shop_id, price };
};

// Creates the order + order_items row.
//
// orders(order_id, customer_id, address_id, total_amount, payment_method,
//        payment_status, order_status, created_at, updated_at)
// order_items(order_item_id, order_id, shop_id, product_id, variant_id,
//             quantity, price, item_status, created_at, updated_at)
//
// total_amount is NOT NULL on orders, so it must be set on insert —
// this is what was missing before (price * quantity).
exports.createOrder = async (customerId, productId, variantId, quantity, shopId, price) => {
    const totalAmount = price * quantity;

    const orderResult = await pool.query(
        `INSERT INTO orders (customer_id, total_amount, payment_method, created_at)
         VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
         RETURNING order_id`,
        [customerId, totalAmount, "COD"]
    );

    const orderId = orderResult.rows[0].order_id;

    const itemResult = await pool.query(
        `INSERT INTO order_items
            (order_id, shop_id, product_id, variant_id, quantity, price, item_status, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, 'Processing', CURRENT_TIMESTAMP)
         RETURNING order_item_id`,
        [orderId, shopId, productId, variantId || null, quantity, price]
    );

    return { orderId, orderItemId: itemResult.rows[0].order_item_id };
};

// Places a SINGLE order containing MULTIPLE items — used by "Buy Now" from
// the Cart screen, where the customer can be checking out several products
// (possibly from different shops) at once. Wrapped in a transaction so a
// failure on one item never leaves a half-created order behind.
//
// items: [{ productId, variantId, quantity, shopId, price }]
exports.createOrderFromItems = async (customerId, items) => {
    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        const totalAmount = items.reduce((sum, i) => sum + i.price * i.quantity, 0);

        const orderResult = await client.query(
            `INSERT INTO orders (customer_id, total_amount, payment_method, created_at)
             VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
             RETURNING order_id`,
            [customerId, totalAmount, "COD"]
        );
        const orderId = orderResult.rows[0].order_id;

        const orderItemIds = [];
        for (const item of items) {
            const itemResult = await client.query(
                `INSERT INTO order_items
                    (order_id, shop_id, product_id, variant_id, quantity, price, item_status, created_at)
                 VALUES ($1, $2, $3, $4, $5, $6, 'Processing', CURRENT_TIMESTAMP)
                 RETURNING order_item_id`,
                [orderId, item.shopId, item.productId, item.variantId || null, item.quantity, item.price]
            );
            orderItemIds.push(itemResult.rows[0].order_item_id);
        }

        await client.query("COMMIT");
        return { orderId, orderItemIds };
    } catch (err) {
        await client.query("ROLLBACK");
        throw err;
    } finally {
        client.release();
    }
};*/
