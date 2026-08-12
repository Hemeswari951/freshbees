const jwt = require("jsonwebtoken");
const pool = require("../config/db");

module.exports = async (req, res, next) => {

    try {

        const customerAuthHeader = req.headers.authorization;

        if (!customerAuthHeader) {
            return res.status(401).json({
                success: false,
                message: "Token Missing"
            });
        }

        if (!customerAuthHeader.startsWith("Bearer ")) {

            return res.status(401).json({
                success: false,
                message: "Invalid Authorization Header"
            });

        }

        const token = customerAuthHeader.split(" ")[1];

        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );

        const result = await pool.query(
            `
            SELECT
                customer_id,
                first_name,
                last_name,
                email,
                phone,
                is_blocked
            FROM customers
            WHERE customer_id = $1
            `,
            [decoded.customer_id]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Account not found"
            });
        }

        const row = result.rows[0];

        if (row.is_blocked) {
            return res.status(403).json({
                success: false,
                message: "Your account has been blocked. Please contact support."
            });
        }

        req.customer = {
            customerId: row.customer_id,
            firstName: row.first_name,
            lastName: row.last_name,
            email: row.email,
            phone: row.phone,
        };

        next();

    } catch (err) {

        return res.status(401).json({
            success: false,
            message: "Invalid Token"
        });

    }

};