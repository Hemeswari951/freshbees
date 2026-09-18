const profileModel = require("../../models/customer/profile.model");

// =====================================================
// GET MAIN CUSTOMER PROFILE
// GET /api/customer/profile
// =====================================================

exports.getProfile = async (req, res) => {
    try {
        // Customer ID comes from JWT authentication middleware.
        const customerId = req.customer.customerId;

        const profile =
            await profileModel.getProfile(customerId);

        if (!profile) {
            return res.status(404).json({
                success: false,
                message: "Customer profile not found",
            });
        }

        return res.status(200).json({
            success: true,
            data: profile,
        });

    } catch (err) {
        console.error("[getProfile]", err);

        return res.status(500).json({
            success: false,
            message: "Failed to fetch customer profile",
        });
    }
};

// =====================================================
// UPDATE MAIN CUSTOMER PROFILE
// PUT /api/customer/profile
// =====================================================

exports.updateProfile = async (req, res) => {
    try {
        const customerId = req.customer.customerId;

        const {
            first_name,
            last_name,
            gender,
            date_of_birth,
            phone,
            email,
            city,
            state,
        } = req.body;

        const profile = await profileModel.updateProfile(
            customerId,
            {
                firstName: first_name,
                lastName: last_name,
                gender,
                dateOfBirth: date_of_birth,
                phone,
                email,
                city,
                state,
            }
        );

        if (!profile) {
            return res.status(404).json({
                success: false,
                message: "Customer profile not found",
            });
        }

        return res.status(200).json({
            success: true,
            message: "Profile updated successfully",
            data: profile,
        });

    } catch (err) {
        console.error("[updateProfile]", err);

        return res.status(500).json({
            success: false,
            message: "Failed to update customer profile",
        });
    }
};