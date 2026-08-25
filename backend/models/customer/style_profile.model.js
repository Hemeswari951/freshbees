const pool = require("../../config/db");

/**
 * Get the style profile for a customer.
 *
 * @param {number} customerId
 * @returns {object|null}
 */
exports.getStyleProfile = async (customerId) => {
    const result = await pool.query(
        `
        SELECT
            profile_id,
            customer_id,
            age_range,
            apparel_size,
            fit_preference,
            preferred_colors,
            preferred_styles,
            created_at,
            updated_at
        FROM customer_style_profiles
        WHERE customer_id = $1
        LIMIT 1
        `,
        [customerId]
    );

    return result.rows[0] || null;
};


/**
 * Create or update a customer's style profile.
 *
 * Because customer_id is UNIQUE, we can use
 * PostgreSQL's ON CONFLICT to handle both cases:
 *
 * - No profile exists → INSERT
 * - Profile already exists → UPDATE
 */
exports.saveStyleProfile = async (
    customerId,
    {
        ageRange,
        apparelSize,
        fitPreference,
        preferredColors,
        preferredStyles,
    }
) => {
    const result = await pool.query(
        `
        INSERT INTO customer_style_profiles (
            customer_id,
            age_range,
            apparel_size,
            fit_preference,
            preferred_colors,
            preferred_styles,
            created_at,
            updated_at
        )
        VALUES (
            $1,
            $2,
            $3,
            $4,
            $5,
            $6,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        )

        ON CONFLICT (customer_id)
        DO UPDATE SET
            age_range = EXCLUDED.age_range,
            apparel_size = EXCLUDED.apparel_size,
            fit_preference = EXCLUDED.fit_preference,
            preferred_colors = EXCLUDED.preferred_colors,
            preferred_styles = EXCLUDED.preferred_styles,
            updated_at = CURRENT_TIMESTAMP

        RETURNING
            profile_id,
            customer_id,
            age_range,
            apparel_size,
            fit_preference,
            preferred_colors,
            preferred_styles,
            created_at,
            updated_at
        `,
        [
            customerId,
            ageRange || null,
            apparelSize || null,
            fitPreference || null,
            preferredColors || [],
            preferredStyles || [],
        ]
    );

    return result.rows[0];
};