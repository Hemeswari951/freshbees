const pool = require("../../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

exports.login = async (req, res) => {

    try {

        const { email, password } = req.body;

        if (!email || !password) {

            return res.status(400).json({
                success: false,
                message: "Email and Password are required"
            });

        }

        const result = await pool.query(
            `
            SELECT *
            FROM admins
            WHERE email=$1
            AND is_active=true
            `,
            [email]
        );

        if (result.rows.length === 0) {

            return res.status(401).json({
                success: false,
                message: "Invalid Email or Password"
            });

        }

        const admin = result.rows[0];

        const isPasswordCorrect = await bcrypt.compare(
            password,
            admin.password_hash
        );

        if (!isPasswordCorrect) {

            return res.status(401).json({
                success: false,
                message: "Invalid Email or Password"
            });

        }

        const token = jwt.sign(

            {
                admin_id: admin.admin_id
            },

            process.env.JWT_SECRET,

            {
                expiresIn: "7d"
            }

        );

        await pool.query(
            `
                UPDATE admins
                SET
                    last_login = CURRENT_TIMESTAMP,
                    login_at = CURRENT_TIMESTAMP,
                    is_logged_in = true
                WHERE admin_id = $1
            `,
            [admin.admin_id]
        );


        return res.status(200).json({

            success: true,

            message: "Login Successful",

            token,

            admin: {

                admin_id: admin.admin_id,

                full_name: admin.full_name,

                email: admin.email,

                role: admin.role,

            }

        });

    }

    catch (err) {

        console.log("Admin Login Error:", err);

        res.status(500).json({

            success: false,

            message: "Server Error"

        });

    }

};


exports.logout = async (req, res) => {

    try {

        await pool.query(
            `
            UPDATE admins
            SET
                is_logged_in = false,
                logout_at = CURRENT_TIMESTAMP
            WHERE admin_id = $1
            `,
            [req.admin.admin_id]
        );

        return res.json({
            success: true,
            message: "Logout Successful"
        });

    } catch (err) {

        console.log(err);

        return res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }

};