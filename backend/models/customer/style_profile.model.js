const pool = require("../../config/db");

/**
 * =====================================================
 * GET STYLE PROFILE
 * =====================================================
 *
 * If tryOnProfileId is provided:
 *   → Get style for that Try-On profile.
 *
 * If tryOnProfileId is null:
 *   → Get style for the logged-in customer.
 */
exports.getStyleProfile = async (
    customerId,
    tryOnProfileId = null
) => {

    // =====================================================
    // TRY-ON PROFILE STYLE
    // =====================================================

    if (tryOnProfileId !== null) {

        const result = await pool.query(
            `
            SELECT
                s.style_id,
                s.profile_id,
                s.apparel_size,
                s.fit_preference,
                s.preferred_colors,
                s.preferred_styles,
                s.created_at,
                s.updated_at
            FROM tryon_profile_styles s
            INNER JOIN tryon_profiles p
                ON p.profile_id = s.profile_id
            WHERE s.profile_id = $1
              AND p.customer_id = $2
            LIMIT 1
            `,
            [
                tryOnProfileId,
                customerId,
            ]
        );

        return result.rows[0] || null;
    }


    // =====================================================
    // MAIN CUSTOMER STYLE
    // =====================================================

    const result = await pool.query(
        `
        SELECT
            profile_id,
            customer_id,
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
 * =====================================================
 * SAVE / UPDATE STYLE PROFILE
 * =====================================================
 *
 * If tryOnProfileId is provided:
 *   → Save style for that Try-On profile.
 *
 * If tryOnProfileId is null:
 *   → Save style for the main customer.
 */
exports.saveStyleProfile = async (
    customerId,
    {
        tryOnProfileId = null,
        apparelSize,
        fitPreference,
        preferredColors,
        preferredStyles,
    }
) => {

    // =====================================================
    // TRY-ON PROFILE STYLE
    // =====================================================

    if (tryOnProfileId !== null) {

        // -------------------------------------------------
        // Security check:
        // Make sure this Try-On profile belongs
        // to the logged-in customer.
        // -------------------------------------------------

        const profileCheck = await pool.query(
            `
            SELECT profile_id
            FROM tryon_profiles
            WHERE profile_id = $1
              AND customer_id = $2
            LIMIT 1
            `,
            [
                tryOnProfileId,
                customerId,
            ]
        );

        if (profileCheck.rows.length === 0) {
            throw new Error(
                "Try-on profile not found"
            );
        }


        // -------------------------------------------------
        // Create or update Try-On style profile
        // -------------------------------------------------

        const result = await pool.query(
            `
            INSERT INTO tryon_profile_styles (
                profile_id,
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
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP
            )

            ON CONFLICT (profile_id)
            DO UPDATE SET
                apparel_size =
                    EXCLUDED.apparel_size,

                fit_preference =
                    EXCLUDED.fit_preference,

                preferred_colors =
                    EXCLUDED.preferred_colors,

                preferred_styles =
                    EXCLUDED.preferred_styles,

                updated_at =
                    CURRENT_TIMESTAMP

            RETURNING
                style_id,
                profile_id,
                apparel_size,
                fit_preference,
                preferred_colors,
                preferred_styles,
                created_at,
                updated_at
            `,
            [
                tryOnProfileId,
                apparelSize || null,
                fitPreference || null,
                preferredColors || [],
                preferredStyles || [],
            ]
        );

        return result.rows[0];
    }


    // =====================================================
    // MAIN CUSTOMER STYLE
    // =====================================================

    const result = await pool.query(
        `
        INSERT INTO customer_style_profiles (
            customer_id,
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
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        )

        ON CONFLICT (customer_id)
        DO UPDATE SET
            apparel_size =
                EXCLUDED.apparel_size,

            fit_preference =
                EXCLUDED.fit_preference,

            preferred_colors =
                EXCLUDED.preferred_colors,

            preferred_styles =
                EXCLUDED.preferred_styles,

            updated_at =
                CURRENT_TIMESTAMP

        RETURNING
            profile_id,
            customer_id,
            apparel_size,
            fit_preference,
            preferred_colors,
            preferred_styles,
            created_at,
            updated_at
        `,
        [
            customerId,
            apparelSize || null,
            fitPreference || null,
            preferredColors || [],
            preferredStyles || [],
        ]
    );

    return result.rows[0];
};