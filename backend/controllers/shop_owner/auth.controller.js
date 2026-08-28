const pool = require("../../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const crypto = require('crypto');
const { sendOtpMail } = require('../../services/shared/sendotpmail.service');

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
            SELECT
                so.*,
                s.is_blocked
            FROM shop_owners so
            JOIN shops s
                ON so.shop_id = s.shop_id
            WHERE so.email = $1
            `,
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Invalid Email or Password"
            });

        }

        const shopOwner = result.rows[0];

        if (shopOwner.is_blocked) {

            return res.status(403).json({
                success: false,
                message: "Your account has been blocked. Please contact Admin."
            });

        }

        const isPasswordCorrect = await bcrypt.compare(
            password,
            shopOwner.password_hash
        );

        if (!isPasswordCorrect) {

            return res.status(401).json({
                success: false,
                message: "Invalid Email or Password"
            });

        }

        if (!shopOwner.is_password_changed) {

            return res.status(200).json({

                success: true,

                firstLogin: true,

                ownerId: shopOwner.shop_owner_id,

                message: "Please change your temporary password."

            });

        }

        const token = jwt.sign(

            {
                owner_id: shopOwner.shop_owner_id
            },

            process.env.JWT_SECRET,

            {
                expiresIn: "7d"
            }

        );

        await pool.query(
            `
                UPDATE shop_owners
                SET
                    last_login = CURRENT_TIMESTAMP,
                    login_at = CURRENT_TIMESTAMP,
                    is_logged_in = true
                WHERE shop_owner_id = $1
            `,
            [shopOwner.shop_owner_id]
        );


        return res.status(200).json({

            success: true,

            message: "Login Successful",

            token,

            firstLogin: false,

            shop_owner: {

                shop_owner_id: shopOwner.shop_owner_id,

                full_name: shopOwner.full_name,

                email: shopOwner.email,

            }

        });



    }

    catch (err) {

        console.log("Shop Owner Login Error:", err);

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
            UPDATE shop_owners  
            SET
                is_logged_in = false,
                logout_at = CURRENT_TIMESTAMP
            WHERE shop_owner_id = $1
            `,
            [req.shopOwner.shop_owner_id]
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

exports.forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                message: "Email is required"
            });
        }

        const result = await pool.query(
            `
                SELECT * from shop_owners
                WHERE email = $1
            `,
            [email]
        );


        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "There is No account. Check your email"
            });
        }

        const otp = crypto.randomInt(100000, 999999).toString();
        const hashedOtp = await bcrypt.hash(otp, 10);
        const expiresAt = new Date(Date.now() + 2 * 60 * 1000);

        await pool.query(
            `DELETE FROM otp_verifications WHERE email = $1 AND portal = $2`,
            [email, 'shop_owner']
        );

        await pool.query(
            `INSERT INTO otp_verifications
             (email, portal, purpose, otp_code, expires_at)
             VALUES ($1, $2, $3, $4, $5)`,
            [email, 'shop_owner', 'password_reset', hashedOtp, expiresAt]
        );

        await sendOtpMail({
            toEmail: email,
            otp: otp,
            purpose: 'password_reset'
        });
        return res.status(200).json({
            success: true,
            message: "OTP sent to your Email"
        });

    } catch (err) {
        console.error("Forgot Password Error:", err);

        return res.status(500).json({
            success: false,
            message: "Server Error"
        });
    }
};


exports.verifyOtp = async (req, res) => {
    try {
        const { email, otp } = req.body;

        if (!email || !otp) {
            return res.status(400).json({
                success: false,
                message: "Email and OTP are required"
            });
        }

        const result = await pool.query(
            `SELECT * FROM otp_verifications WHERE email = $1 AND portal = $2`,
            [email, 'shop_owner']
        );

        if (result.rows.length === 0) {
            return res.status(400).json({
                success: false,
                message: "OTP not found. Please request a new one"
            });
        }

        const otpRow = result.rows[0];

        // Purpose check
        if (otpRow.purpose !== 'password_reset') {
            return res.status(400).json({
                success: false,
                message: "Invalid request"
            });
        }

        // Expiry check
        if (new Date() > new Date(otpRow.expires_at)) {
            return res.status(400).json({
                success: false,
                message: "OTP expired. Please request a new one"
            });
        }

        // Attempts check
        if (otpRow.attempts >= 5) {
            return res.status(400).json({
                success: false,
                message: "Too many failed attempts. Please request a new OTP"
            });
        }

        // OTP match check
        const isMatch = await bcrypt.compare(otp, otpRow.otp_code);

        if (!isMatch) {
            await pool.query(
                `UPDATE otp_verifications SET attempts = attempts + 1 
                 WHERE email = $1 AND portal = $2`,
                [email, 'shop_owner']
            );

            return res.status(400).json({
                success: false,
                message: "Invalid OTP"
            });
        }

        // Success - mark verified
        await pool.query(
            `UPDATE otp_verifications SET is_verified = true 
             WHERE email = $1 AND portal = $2`,
            [email, 'shop_owner']
        );

        return res.status(200).json({
            success: true,
            message: "OTP verified successfully"
        });

    } catch (err) {
        console.error("Verify OTP Error:", err);
        return res.status(500).json({
            success: false,
            message: "Server Error"
        });
    }
};


exports.resetPassword = async (req, res) => {

    try {

        const { ownerId, email, password } = req.body;

        if (!password) {
            return res.status(400).json({
                success: false,
                message: "Password is required"
            });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        // FIRST LOGIN
        if (ownerId) {

            await pool.query(
                `
                UPDATE shop_owners
                SET
                    password_hash = $1,
                    is_password_changed = true,
                    updated_at = CURRENT_TIMESTAMP
                WHERE shop_owner_id = $2
                `,
                [passwordHash, ownerId]
            );

            return res.status(200).json({
                success: true,
                message: "Password changed successfully"
            });

        }

        // FORGOT PASSWORD FLOW
        else if (email) {

            // OTP verify aaguthaa nu check pannuங்க
            const otpResult = await pool.query(
                `SELECT * FROM otp_verifications 
                 WHERE email = $1 AND portal = $2`,
                [email, 'shop_owner']
            );

            if (otpResult.rows.length === 0 || !otpResult.rows[0].is_verified) {
                return res.status(400).json({
                    success: false,
                    message: "OTP not verified. Please verify OTP first"
                });
            }

            const otpRow = otpResult.rows[0];

            // Verified OTP-ku expiry check bhi (extra safety, e.g. verify pannitu 10 mins delay pannினா)
            if (new Date() > new Date(otpRow.expires_at)) {
                return res.status(400).json({
                    success: false,
                    message: "Session expired. Please verify OTP again"
                });
            }

            await pool.query(
                `UPDATE shop_owners
                 SET password_hash = $1, 
                    is_password_changed = true,
                    updated_at = CURRENT_TIMESTAMP
                 WHERE email = $2`,
                [passwordHash, email]
            );

            // Password reset aana odane OTP row delete pannunga (reuse thadka)
            await pool.query(
                `DELETE FROM otp_verifications WHERE email = $1 AND portal = $2`,
                [email, 'shop_owner']
            );

            return res.status(200).json({
                success: true,
                message: "Password reset successfully"
            });

        }

        else {
            return res.status(400).json({
                success: false,
                message: "ownerId or email is required"
            });
        }

    } catch (err) {

        console.log("Reset Password Error:", err);

        return res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }

};