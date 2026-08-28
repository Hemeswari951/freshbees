const homeService = require("../../services/shop_owner/home.service");

exports.getHome = async (req, res) => {
    try {
        const shopOwnerId = req.shopOwner.shopOwnerId;

        const homeData = await homeService.buildHomeData(shopOwnerId);

        return res.status(200).json({
            success: true,
            data: homeData
        });

    } catch (err) {
        console.error("Home Error:", err);

        if (err.message === "Shop not found") {
            return res.status(404).json({ success: false, message: "Shop not found" });
        }

        return res.status(500).json({ success: false, message: "Server Error" });
    }
};