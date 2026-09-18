const tryOnProfileStyleModel = require(
  "../../models/customer/tryon_profile_style.model"
);

// =====================================================
// GET STYLE FOR A TRY-ON PROFILE
// GET /api/customer/tryon-profiles/:id/style
// =====================================================

exports.getStyle = async (req, res) => {
  try {
    const customerId = req.customer.customerId;
    const profileId = Number(req.params.id);

    // ---------------------------------------------
    // Validate profile ID
    // ---------------------------------------------

    if (!profileId) {
      return res.status(400).json({
        success: false,
        message: "Invalid try-on profile ID",
      });
    }

    // ---------------------------------------------
    // Get style
    // ---------------------------------------------

    const style =
      await tryOnProfileStyleModel.getByProfileId(
        profileId,
        customerId
      );

    // No style saved yet
    if (!style) {
      return res.status(200).json({
        success: true,
        data: null,
      });
    }

    return res.status(200).json({
      success: true,
      data: style,
    });

  } catch (err) {
    console.error(
      "[getTryOnProfileStyle]",
      err
    );

    return res.status(500).json({
      success: false,
      message: "Failed to fetch try-on profile style",
    });
  }
};


// =====================================================
// SAVE / UPDATE STYLE FOR A TRY-ON PROFILE
// PUT /api/customer/tryon-profiles/:id/style
// =====================================================

exports.saveStyle = async (req, res) => {
  try {
    const customerId = req.customer.customerId;
    const profileId = Number(req.params.id);

    console.log("========== SAVE TRY-ON STYLE ==========");
    console.log("customerId:", customerId);
    console.log("profileId:", profileId);
    console.log("body:", req.body);

    // ---------------------------------------------
    // Validate profile ID
    // ---------------------------------------------

    if (!profileId) {
      return res.status(400).json({
        success: false,
        message: "Invalid try-on profile ID",
      });
    }

    const {
      apparel_size,
      fit_preference,
      preferred_colors,
      preferred_styles,
    } = req.body;

    // ---------------------------------------------
    // Validate arrays
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
    // Save / update
    // ---------------------------------------------

    const style =
      await tryOnProfileStyleModel.save(
        profileId,
        customerId,
        {
          apparelSize: apparel_size,
          fitPreference: fit_preference,
          preferredColors: preferred_colors,
          preferredStyles: preferred_styles,
        }
      );

    // Profile doesn't belong to this customer
    if (!style) {
      return res.status(404).json({
        success: false,
        message: "Try-on profile not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Try-on profile style saved successfully",
      data: style,
    });

  } catch (err) {
    console.error(
      "[saveTryOnProfileStyle]",
      err
    );

    return res.status(500).json({
      success: false,
      message: "Failed to save try-on profile style",
    });
  }
};