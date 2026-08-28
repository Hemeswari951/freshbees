const styleProfileModel = require("../../models/customer/style_profile.model");

// =====================================================
// GET CUSTOMER STYLE PROFILE
// GET /api/customer/style-profile
// =====================================================

exports.getStyleProfile = async (req, res) => {
    try {
        // Customer ID comes from the authenticated JWT middleware.
        const customerId = req.customer.customerId;

        const profile =
            await styleProfileModel.getStyleProfile(customerId);

        return res.status(200).json({
            success: true,
            data: profile,
        });

    } catch (err) {
        console.error("[getStyleProfile]", err);

        return res.status(500).json({
            success: false,
            message: "Failed to fetch style profile",
        });
    }
};


// =====================================================
// SAVE / UPDATE CUSTOMER STYLE PROFILE
// PUT /api/customer/style-profile
// =====================================================

exports.saveStyleProfile = async (req, res) => {
    try {
        // IMPORTANT:
        // Do NOT take customer_id from req.body.
        // It comes from the authenticated customer.
        const customerId = req.customer.customerId;

        const {
            age_range,
            apparel_size,
            fit_preference,
            preferred_colors,
            preferred_styles,
        } = req.body;

        // ---------------------------------------------
        // Basic validation
        // ---------------------------------------------

        if (
            preferred_colors !== undefined &&
            !Array.isArray(preferred_colors)
        ) {
            return res.status(400).json({
                success: false,
                message: "preferred_colors must be an array",
            });
        }

        if (
            preferred_styles !== undefined &&
            !Array.isArray(preferred_styles)
        ) {
            return res.status(400).json({
                success: false,
                message: "preferred_styles must be an array",
            });
        }

        // ---------------------------------------------
        // Save profile
        // ---------------------------------------------

        const profile =
            await styleProfileModel.saveStyleProfile(
                customerId,
                {
                    ageRange: age_range,
                    apparelSize: apparel_size,
                    fitPreference: fit_preference,
                    preferredColors: preferred_colors,
                    preferredStyles: preferred_styles,
                }
            );

        return res.status(200).json({
            success: true,
            message: "Style profile saved successfully",
            data: profile,
        });

    } catch (err) {
        console.error("[saveStyleProfile]", err);

        return res.status(500).json({
            success: false,
            message: "Failed to save style profile",
        });
    }
};