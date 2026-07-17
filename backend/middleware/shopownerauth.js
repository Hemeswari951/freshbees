const jwt = require("jsonwebtoken");
const pool = require("../config/db");

module.exports = async (req, res, next) => {

    try {

        const shopOwnerAuthHeader = req.headers.authorization;

        if (!shopOwnerAuthHeader) {
            return res.status(401).json({
                success: false,
                message: "Token Missing"
            });
        }

        if (!shopOwnerAuthHeader.startsWith("Bearer ")) {

            return res.status(401).json({
                success: false,
                message: "Invalid Authorization Header"
            });

        }

        const token = shopOwnerAuthHeader.split(" ")[1];

        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );

        const result = await pool.query(
            `
            SELECT
                so.shop_owner_id,
                so.shop_id,
                so.full_name,
                so.email
            FROM shop_owners so
            jOIN shops s
                ON so.shop_id = s.shop_id
            WHERE so.shop_owner_id = $1
            AND s.is_blocked = false
            `,
            [decoded.owner_id]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Shop has been blocked by Admin. Please contact Admin."
            });
        }

        const row = result.rows[0];
        req.shopOwner = {
            shopOwnerId: row.shop_owner_id,
            shopId: row.shop_id,
            fullName: row.full_name,
            email: row.email,
        };

        next();

    } catch (err) {

        return res.status(401).json({
            success: false,
            message: "Invalid Token"
        });

    }

};