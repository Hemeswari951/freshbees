/*--- This file ONLY communicates with PostgreSQL. ---*/
const pool = require("../../config/db");

/*
=========================================
Admin's Customer Dashboard
=========================================
*/

const countCustomers = async () => {

    const result = await pool.query(
        `
        SELECT COUNT(*) AS total
        FROM customers
        `
    );

    return result.rows[0];

};

const countTodayCustomers = async () => {

    const result = await pool.query(
        `
        SELECT COUNT(*) AS total
        FROM customers
        WHERE DATE(created_at)=CURRENT_DATE
        `
    );

    return result.rows[0];

};

const countBlockedCustomers = async () => {

    const result = await pool.query(
        `
        SELECT COUNT(*) AS total
        FROM customers
        WHERE is_blocked=true
        `
    );

    return result.rows[0];

};


/*
=========================================
Customer List
=========================================
*/
const getCustomers = async (filters) => {

    let query = `
        SELECT

            customer_id,
            profile_image,
            first_name,
            last_name,
            email,
            phone,
            city,
            is_blocked

        FROM customers

        WHERE 1=1
    `;

    const values = [];

    // Today's Customers
    if (filters.type === "today") {

        query += ` AND DATE(created_at) = CURRENT_DATE`;

    }

    // Blocked Customers Card
    if (filters.type === "blocked") {

        query += ` AND is_blocked = true`;

    }

    // Search
    if (filters.search) {

        values.push(`%${filters.search}%`);

        query += `
            AND
            (
                first_name ILIKE $${values.length}
                OR
                last_name ILIKE $${values.length}
            )
        `;

    }

    // City Filter
    if (filters.city) {

        values.push(filters.city);

        query += ` AND city = $${values.length}`;

    }

    // Status Filter
    if (filters.status) {

        if (filters.status === "blocked") {

            query += ` AND is_blocked = true`;

        }

        if (filters.status === "unblocked") {

            query += ` AND is_blocked = false`;

        }

    }

    query += ` ORDER BY customer_id DESC`;

    const result = await pool.query(query, values);

    return result.rows;

};

/*
=========================================
Customer Details
=========================================
*/
const getCustomerById = async (customerId) => {

    const result = await pool.query(
        `
        SELECT

        customer_id,

        profile_image,

        first_name,

        last_name,

        email,

        phone,

        gender,

        city,

        state,

        date_of_birth,

        last_login,

        created_at,

        is_blocked

        FROM customers

        WHERE customer_id=$1
        `,
        [customerId]
    );

    return result.rows[0];

};

/*
=========================================
Customer Details - Update Status(Block or Unblock)
=========================================
*/
const updateCustomerStatus = async (
    customerId,
    status
) => {

    const result = await pool.query(
        `
        UPDATE customers

        SET

        is_blocked=$1,

        updated_at=NOW()

        WHERE customer_id=$2

        RETURNING *
        `,
        [
            status,
            customerId
        ]
    );

    return result.rows[0];

};

/*---------------------- EXPORT ------------------ */
module.exports = {
    countCustomers,
    countTodayCustomers,
    countBlockedCustomers,
    getCustomers,
    getCustomerById,
    updateCustomerStatus
};