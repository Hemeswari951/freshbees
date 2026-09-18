const pool = require("../../config/db");

/**
 * Get the logged-in customer's complete profile.
 *
 * Combines:
 *   customers
 *   customer_style_profiles
 */
exports.getProfile = async (customerId) => {
    const result = await pool.query(
        `
        SELECT
            c.customer_id,
            c.first_name,
            c.last_name,
            c.email,
            c.phone,
            c.profile_image,
            c.gender,
            c.city,
            c.state,
            TO_CHAR(c.date_of_birth, 'YYYY-MM-DD') AS date_of_birth, 
            c.is_verified,
            c.created_at,
            c.updated_at,

            sp.profile_id AS style_profile_id,
            sp.apparel_size,
            sp.fit_preference,
            sp.preferred_colors,
            sp.preferred_styles

        FROM customers c

        LEFT JOIN customer_style_profiles sp
            ON sp.customer_id = c.customer_id

        WHERE c.customer_id = $1

        LIMIT 1
        `,
        [customerId]
    );

    return result.rows[0] || null;
};

exports.updateProfile = async (
    customerId,
    {
        firstName,
        lastName,
        gender,
        dateOfBirth,
        phone,
        email,
        city,
        state,
    }
) => {

    const result = await pool.query(
        `
        UPDATE customers
        SET
            first_name = COALESCE($2, first_name),
            last_name = COALESCE($3, last_name),
            gender = COALESCE($4, gender),
            date_of_birth = COALESCE($5, date_of_birth),

            email = COALESCE($6, email),
            city = COALESCE($7, city),
            state = COALESCE($8, state),

            updated_at = CURRENT_TIMESTAMP

        WHERE customer_id = $1

        RETURNING
            customer_id,
            first_name,
            last_name,
            email,
            phone,
            profile_image,
            gender,
            city,
            state,
            TO_CHAR(date_of_birth, 'YYYY-MM-DD') AS date_of_birth,
            is_verified,
            created_at,
            updated_at
        `,
        [
            customerId, // $1
            firstName,  // $2
            lastName,   // $3
            gender,     // $4
            dateOfBirth,// $5
            email,      // $6
            city,       // $7
            state,      // $8
        ]
    );

    return result.rows[0] || null;
};