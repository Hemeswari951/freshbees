const shopService = require('../../services/admin/shop.service');

// GET /api/admin/shops
// → Returns all shops with stats (for ShopsScreen grid + stat cards)
async function listShops(req, res) {
    try {
        const shops = await shopService.getAllShops();
        res.json({ success: true, data: shops });
    } catch (err) {
        console.error('[listShops]', err);
        res.status(500).json({ success: false, message: 'Failed to fetch shops' });
    }
}

// GET /api/admin/shops/:id
// → Returns single shop detail (for ShopDetailScreen)
async function getShop(req, res) {
  try {
    const shop = await shopService.getShopDetail(req.params.id);
    if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });
    res.json({ success: true, data: shop });
  } catch (err) {
    console.error('[getShop]', err);
    res.status(500).json({ success: false, message: 'Failed to fetch shop' });
  }
}

// POST /api/admin/shops
// → Creates a shop from the 4-step Add Shop form
// → Body: JSON fields + multipart files (logo, banner via multer)
async function createShop(req, res) {
    try {
        if (req.body.categoryIds) {

            req.body.categoryIds =
                JSON.parse(req.body.categoryIds);

        }
        const shop = await shopService.createShop(req.body, req.files);
        res.status(201).json({ success: true, data: shop });
    } catch (err) {
        console.error('[createShop]', err);
        // Duplicate email/phone will throw a Postgres unique-constraint error
        if (err.code === '23505') {
            return res.status(409).json({
                success: false,
                message: 'A shop owner with this email or phone already exists',
            });
        }
        res.status(500).json({ success: false, message: 'Failed to create shop' });
    }
}


// PATCH /api/admin/shops/:id/status
// Body:
// {
//   "status": "blocked" | "active",
//   "reason": "Optional reason"
// }

// PATCH /api/admin/shops/:id/status
async function updateShopStatus(req, res) {
    try {
        const { status, reason } = req.body;

        if (!status) {
            return res.status(400).json({
                success: false,
                message: "`status` is required",
            });
        }

        let block;

        switch (status) {
            case "blocked":
                block = true;
                break;

            case "active":
                block = false;
                break;

            default:
                return res.status(400).json({
                    success: false,
                    message: "Invalid status. Allowed values: active, blocked",
                });
        }

        const result = await shopService.updateShopStatus(
            req.params.id,
            block,
            reason
        );

        res.json({
            success: true,
            data: result,
        });
    } catch (err) {
        console.error("[updateShopStatus]", err);

        res.status(500).json({
            success: false,
            message: "Failed to update shop status",
        });
    }
}


async function updateBasicInfo(req, res) {

    try {

        // Convert categoryIds string to array
        if (req.body.categoryIds) {

            if (typeof req.body.categoryIds === "string") {

                req.body.categoryIds = JSON.parse(req.body.categoryIds);

            }

        }

        const result = await shopService.updateBasicInfo(

            req.params.id,

            req.body,

        );

        res.json({

            success: true,

            data: result,

        });

    } catch (err) {

        console.error("[updateBasicInfo]", err);

        res.status(500).json({

            success: false,

            message: "Failed to update shop information",

        });

    }

}

async function updateOwnerInfo(req, res) {

    try {

        const result =
            await shopService.updateOwnerInfo(
                req.params.id,
                req.body,
            );

        res.json({

            success: true,

            data: result,

        });

    } catch (err) {

        console.error("[updateOwnerInfo]", err);

        res.status(500).json({

            success: false,

            message: "Failed to update owner",

        });

    }

}
async function updateBankInfo(req, res) {

    try {

        const result = await shopService.updateBankInfo(

            req.params.id,

            req.body,

        );

        res.json({

            success: true,

            data: result,

        });

    } catch (err) {

        console.error("[updateBankInfo]", err);

        res.status(500).json({

            success: false,

            message: "Failed to update bank details",

        });

    }

}
async function updateSettings(req, res) {

    try {

        const result = await shopService.updateSettings(

            req.params.id,

            req.body,

        );

        res.json({

            success: true,

            data: result,

        });

    } catch (err) {

        console.error("[updateSettings]", err);

        res.status(500).json({

            success: false,

            message: "Failed to update settings",

        });

    }

}


module.exports = {
    listShops, createShop, getShop, updateShopStatus,
    updateBasicInfo,
    updateOwnerInfo, updateBankInfo,
    updateSettings,
};