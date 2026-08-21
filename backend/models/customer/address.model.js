
const pool = require("../../config/db");

// Every saved address for a customer, default address first.
exports.getAddressesByCustomer = async (customerId) => {
    const result = await pool.query(
        `SELECT address_id, full_name, phone, address_line1, address_line2,
                city, state, country, pincode, address_type, is_default
         FROM addresses
         WHERE customer_id = $1
         ORDER BY is_default DESC, created_at DESC`,
        [customerId]
    );
    return result.rows;
};

// Used by order.controller.js to make sure the address_id sent at checkout
// actually belongs to the logged-in customer before an order is created
// against it.
exports.getAddressById = async (customerId, addressId) => {
    const result = await pool.query(
        `SELECT address_id, full_name, phone, address_line1, address_line2,
                city, state, country, pincode, address_type, is_default
         FROM addresses WHERE address_id = $1 AND customer_id = $2`,
        [addressId, customerId]
    );
    return result.rows[0] || null;
};

// Adds a new address. The customer's very first address is always forced
// to be the default regardless of what the client sends, so there's never
// a customer with saved addresses but no default.
exports.addAddress = async (customerId, data) => {
    const {
        full_name, phone, address_line1, address_line2,
        city, state, country, pincode, address_type, is_default
    } = data;

    const client = await pool.connect();
    try {
        await client.query("BEGIN");

        const countResult = await client.query(
            `SELECT COUNT(*)::int AS count FROM addresses WHERE customer_id = $1`,
            [customerId]
        );
        const isFirstAddress = countResult.rows[0].count === 0;
        const shouldBeDefault = isFirstAddress || !!is_default;

        if (shouldBeDefault) {
            await client.query(
                `UPDATE addresses SET is_default = FALSE WHERE customer_id = $1`,
                [customerId]
            );
        }

        const inserted = await client.query(
            `INSERT INTO addresses
                (customer_id, full_name, phone, address_line1, address_line2,
                 city, state, country, pincode, address_type, is_default)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
             RETURNING address_id`,
            [
                customerId, full_name, phone, address_line1, address_line2 || null,
                city || null, state || null, country || "India", pincode || null,
                address_type || "Home", shouldBeDefault
            ]
        );

        await client.query("COMMIT");
        return inserted.rows[0].address_id;
    } catch (err) {
        await client.query("ROLLBACK");
        throw err;
    } finally {
        client.release();
    }
};

exports.setDefaultAddress = async (customerId, addressId) => {
    const client = await pool.connect();
    try {
        await client.query("BEGIN");
        await client.query(
            `UPDATE addresses SET is_default = FALSE WHERE customer_id = $1`,
            [customerId]
        );
        const result = await client.query(
            `UPDATE addresses SET is_default = TRUE
             WHERE address_id = $1 AND customer_id = $2
             RETURNING address_id`,
            [addressId, customerId]
        );
        await client.query("COMMIT");
        return result.rows[0] || null;
    } catch (err) {
        await client.query("ROLLBACK");
        throw err;
    } finally {
        client.release();
    }
};

exports.deleteAddress = async (customerId, addressId) => {
    const result = await pool.query(
        `DELETE FROM addresses WHERE address_id = $1 AND customer_id = $2 RETURNING address_id`,
        [addressId, customerId]
    );
    return result.rows[0] || null;
};
