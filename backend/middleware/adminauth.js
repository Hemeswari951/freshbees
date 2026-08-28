const jwt = require("jsonwebtoken");
const pool = require("../config/db");

module.exports = async (req, res, next) => {

    try {

        const authHeader = req.headers.authorization;

        if (!authHeader) {
            return res.status(401).json({
                success: false,
                message: "Token Missing"
            });
        }

        if (!authHeader.startsWith("Bearer ")) {

            return res.status(401).json({
                success: false,
                message: "Invalid Authorization Header"
            });

        }

        const token = authHeader.split(" ")[1];

        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );

        const result = await pool.query(
            `
            SELECT admin_id
            FROM admins
            WHERE admin_id = $1
            AND is_active = true
            `,
            [decoded.admin_id]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Admin account is inactive"
            });
        }

        req.admin = result.rows[0];

        next();

    } catch (err) {

        return res.status(401).json({
            success: false,
            message: "Invalid Token"
        });

    }

};