const pool = require("../../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { sendOtpMail } = require("../../services/shared/sendotpmail.service");
const { sendOtpSms } = require('../../services/customer/sms.service');

const {
    issueTokens,
    verifyRefreshToken,
    revokeRefreshToken,
} = require("../../services/shared/token.service");

const PORTAL = "customer";

// ==============================
// HELPERS
// ==============================

// Check if identifier is a phone number
function isPhone(identifier) {
    return /^[0-9]{10}$/.test(identifier.replace(/\D/g, "").slice(-10));
}

// Normalize phone to last 10 digits (consistent storage/lookup everywhere)
function normalizeIdentifier(identifier) {
    const raw = (identifier || "").toString().trim().toLowerCase();
    if (isPhone(raw)) {
        return raw.replace(/\D/g, "").slice(-10);
    }
    return raw; // email - already lowercased/trimmed
}

// ==============================
// 1. SEND OTP
// ==============================
exports.sendOtp = async (req, res) => {
    try {
        const identifier = normalizeIdentifier(req.body.identifier);

        if (!identifier) {
            return res.status(400).json({
                success: false,
                message: "Mobile number or Email is required",
            });
        }

        // Check customer exists
        const customerResult = await pool.query(
            `
      SELECT customer_id, email, phone
      FROM customers
      WHERE email = $1
         OR phone = $1
      `,
            [identifier]
        );

        const isNewUser = customerResult.rows.length === 0;

        let purpose = req.body.purpose;
        if (!purpose || purpose === "auth") {
            purpose = isNewUser ? "registration" : "login";
        }

        // Generate 6-digit OTP
        const otp = crypto.randomInt(100000, 999999).toString();
        const hashedOtp = await bcrypt.hash(otp, 10);
        const expiresAt = new Date(Date.now() + 2 * 60 * 1000); // 2 minutes expiry

        // Delete previous OTP for this identifier & portal (re-send logic)
        await pool.query(
            `
      DELETE FROM otp_verifications
      WHERE identifier = $1
      AND portal = $2
      `,
            [identifier, PORTAL]
        );

        // Save new OTP
        await pool.query(
            `
      INSERT INTO otp_verifications
      (identifier, portal, purpose, otp_code, expires_at)
      VALUES
      ($1, $2, $3, $4, $5)
      `,
            [identifier, PORTAL, purpose, hashedOtp, expiresAt]
        );

        // Terminal logging for testing
        console.log("=========================================");
        console.log(`📱 Identifier       : ${identifier}`);
        console.log(`🔑 Generated OTP   : ${otp}`);
        console.log(`🎯 Portal & Purpose: ${PORTAL} | ${purpose}`);
        console.log("=========================================");

        // Send OTP via SMS or Mail
        if (isPhone(identifier)) {
            await sendOtpSms({
    phoneNumber: identifier,
    otp: otp,
  });
        } else {
            await sendOtpMail({
                toEmail: identifier,
                otp: otp,
                purpose: purpose,
            });
        }

        return res.status(200).json({
            success: true,
            message: "OTP sent successfully",
            isNewUser,
            isPhone: isPhone(identifier),
            identifier,
            purpose,
        });
    } catch (err) {
        console.log("Send OTP Error :", err);

        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ==============================
// 2. VERIFY OTP
// ==============================
exports.verifyOtp = async (req, res) => {
    try {
        const { otp } = req.body;

        if (!req.body.identifier) {
            return res.status(400).json({
                success: false,
                message: "Identifier is required",
            });
        }

        if (!otp) {
            return res.status(400).json({
                success: false,
                message: "OTP is required",
            });
        }

        const identifier = normalizeIdentifier(req.body.identifier);

        // Get OTP record
        const otpResult = await pool.query(
            `
      SELECT *
      FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
      `,
            [identifier, PORTAL]
        );

        if (otpResult.rows.length === 0) {
            return res.status(400).json({
                success: false,
                message: "OTP not found. Please request a new OTP",
            });
        }

        const otpRow = otpResult.rows[0];

        // Check expired
        if (new Date() > new Date(otpRow.expires_at)) {
            return res.status(400).json({
                success: false,
                message: "OTP expired. Please request a new OTP",
            });
        }

        // Check max attempts
        if (otpRow.attempts >= 5) {
            return res.status(400).json({
                success: false,
                message: "Too many failed attempts. Please request a new OTP",
            });
        }

        // Compare OTP
        const isMatch = await bcrypt.compare(otp, otpRow.otp_code);

        if (!isMatch) {
            await pool.query(
                `
        UPDATE otp_verifications
        SET attempts = attempts + 1
        WHERE identifier = $1
          AND portal = $2
        `,
                [identifier, PORTAL]
            );

            return res.status(400).json({
                success: false,
                message: "Invalid OTP",
            });
        }

        // Mark as verified
        await pool.query(
            `
      UPDATE otp_verifications
      SET is_verified = true
      WHERE identifier = $1
        AND portal = $2
      `,
            [identifier, PORTAL]
        );

        // Check customer status
        const customerResult = await pool.query(
            `
      SELECT *
      FROM customers
      WHERE email = $1
         OR phone = $1
      `,
            [identifier]
        );

        // NEW USER - needs to complete registration
        if (customerResult.rows.length === 0) {
            return res.status(200).json({
                success: true,
                isNewUser: true,
                message: "OTP verified successfully",
            });
        }

        // EXISTING USER - log them in
        const customer = customerResult.rows[0];

        if (customer.is_blocked) {
            return res.status(403).json({
                success: false,
                message: "Your account has been blocked.",
            });
        }

        // OTP purpose was login - clean it up now, it's been fully consumed
        await pool.query(
            `
      DELETE FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
      `,
            [identifier, PORTAL]
        );

        const { accessToken, refreshToken } = await issueTokens(
            customer.customer_id,
            PORTAL,
            { customer_id: customer.customer_id }
        );

        // Update last login
        await pool.query(
            `
      UPDATE customers
      SET last_login = CURRENT_TIMESTAMP
      WHERE customer_id = $1
      `,
            [customer.customer_id]
        );

        return res.status(200).json({
            success: true,
            isNewUser: false,
            message: "Login Successful",
            accessToken,
            refreshToken,
            customer: {
                customer_id: customer.customer_id,
                first_name: customer.first_name,
                last_name: customer.last_name,
                email: customer.email,
                phone: customer.phone,
                profile_image: customer.profile_image,
            },
        });
    } catch (err) {
        console.log("Verify OTP Error :", err);

        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ==============================
// 3. REGISTER
// ==============================
exports.register = async (req, res) => {
    try {
        const {
            password,
            first_name,
            last_name,
            gender,
            date_of_birth,
        } = req.body;

        if (
            !req.body.identifier ||
            !password ||
            !first_name ||
            !last_name ||
            !gender ||
            !date_of_birth
        ) {
            return res.status(400).json({
                success: false,
                message: "All fields are required",
            });
        }

        const identifier = normalizeIdentifier(req.body.identifier);

        const otpResult = await pool.query(
            `
      SELECT *
      FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
        AND is_verified = true
      `,
            [identifier, PORTAL]
        );

        if (otpResult.rows.length === 0) {
            return res.status(400).json({
                success: false,
                message: "OTP verification required",
            });
        }

        const existingCustomer = await pool.query(
            `
      SELECT customer_id
      FROM customers
      WHERE email = $1
         OR phone = $1
      `,
            [identifier]
        );

        if (existingCustomer.rows.length > 0) {
            return res.status(409).json({
                success: false,
                message: "Customer already exists",
            });
        }

        const passwordHash = await bcrypt.hash(password, 10);
        const isEmail = identifier.includes("@");

        const customerEmail = isEmail ? identifier : null;
        const customerPhone = isEmail ? null : identifier;

        const customerResult = await pool.query(
            `
      INSERT INTO customers
      (
        first_name,
        last_name,
        email,
        phone,
        password,
        gender,
        date_of_birth,
        is_verified,
        last_login
      )
      VALUES
      ($1, $2, $3, $4, $5, $6, $7, true, CURRENT_TIMESTAMP)
      RETURNING *
      `,
            [
                first_name,
                last_name,
                customerEmail,
                customerPhone,
                passwordHash,
                gender,
                date_of_birth,
            ]
        );

        const customer = customerResult.rows[0];

        // Delete OTP record after successful registration
        await pool.query(
            `
      DELETE FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
      `,
            [identifier, PORTAL]
        );

        const { accessToken, refreshToken } = await issueTokens(
            customer.customer_id,
            PORTAL,
            { customer_id: customer.customer_id }
        );

        return res.status(201).json({
            success: true,
            message: "Registration Successful",
            accessToken,
            refreshToken,
            customer: {
                customer_id: customer.customer_id,
                first_name: customer.first_name,
                last_name: customer.last_name,
                email: customer.email,
                phone: customer.phone,
                gender: customer.gender,
                date_of_birth: customer.date_of_birth,
                profile_image: customer.profile_image,
            },
        });
    } catch (err) {
        console.error("Register Error:", err);

        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ==============================
// 4. LOGIN (password based)
// ==============================
exports.login = async (req, res) => {
    try {
        const { password } = req.body;

        if (!req.body.identifier || !password) {
            return res.status(400).json({
                success: false,
                message: "Identifier and password are required",
            });
        }

        const identifier = normalizeIdentifier(req.body.identifier);

        const result = await pool.query(
            `
      SELECT *
      FROM customers
      WHERE email = $1
         OR phone = $1
      `,
            [identifier]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Account not found",
            });
        }

        const customer = result.rows[0];

        if (customer.is_blocked) {
            return res.status(403).json({
                success: false,
                message: "Your account has been blocked. Please contact support.",
            });
        }

        const isPasswordCorrect = await bcrypt.compare(password, customer.password);

        if (!isPasswordCorrect) {
            return res.status(401).json({
                success: false,
                message: "Invalid password",
            });
        }

        const { accessToken, refreshToken } = await issueTokens(
            customer.customer_id,
            PORTAL,
            { customer_id: customer.customer_id }
        );

        await pool.query(
            `
      UPDATE customers
      SET last_login = CURRENT_TIMESTAMP
      WHERE customer_id = $1
      `,
            [customer.customer_id]
        );

        return res.status(200).json({
            success: true,
            message: "Login Successful",
            accessToken,
            refreshToken,
            customer: {
                customer_id: customer.customer_id,
                first_name: customer.first_name,
                last_name: customer.last_name,
                email: customer.email,
                phone: customer.phone,
                profile_image: customer.profile_image,
                gender: customer.gender,
            },
        });
    } catch (err) {
        console.log("Customer Login Error:", err);

        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ==============================
// 5. FORGOT PASSWORD
// ==============================
exports.forgotPassword = async (req, res) => {
    try {
        if (!req.body.identifier) {
            return res.status(400).json({
                success: false,
                message: "Mobile number or Email is required",
            });
        }

        const identifier = normalizeIdentifier(req.body.identifier);

        const result = await pool.query(
            `
      SELECT customer_id, email, phone
      FROM customers
      WHERE email = $1
         OR phone = $1
      `,
            [identifier]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Account not found",
            });
        }

        const otp = crypto.randomInt(100000, 999999).toString();
        const hashedOtp = await bcrypt.hash(otp, 10);
        const expiresAt = new Date(Date.now() + 2 * 60 * 1000);

        await pool.query(
            `
      DELETE FROM otp_verifications
      WHERE identifier = $1
      AND portal = $2
      `,
            [identifier, PORTAL]
        );

        await pool.query(
            `
      INSERT INTO otp_verifications
      (identifier, portal, purpose, otp_code, expires_at)
      VALUES
      ($1, $2, $3, $4, $5)
      `,
            [identifier, PORTAL, "forgot_password", hashedOtp, expiresAt]
        );

        console.log("=========================================");
        console.log(`📱 Identifier       : ${identifier}`);
        console.log(`🔑 Generated OTP   : ${otp}`);
        console.log(`🎯 Portal & Purpose: ${PORTAL} | forgot_password`);
        console.log("=========================================");

        if (isPhone(identifier)) {
            // await sendOtpSms(identifier, otp);
        } else {
            await sendOtpMail({
                toEmail: identifier,
                otp: otp,
                purpose: "forgot_password",
            });
        }

        return res.status(200).json({
            success: true,
            message: "OTP sent successfully",
        });
    } catch (err) {
        console.log("Forgot Password Error :", err);

        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ==============================
// 6. RESET PASSWORD
// ==============================
exports.resetPassword = async (req, res) => {
    try {
        const { password } = req.body;

        if (!req.body.identifier || !password) {
            return res.status(400).json({
                success: false,
                message: "Identifier and password are required",
            });
        }

        const identifier = normalizeIdentifier(req.body.identifier);

        const otpResult = await pool.query(
            `
      SELECT *
      FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
        AND is_verified = true
      `,
            [identifier, PORTAL]
        );

        if (otpResult.rows.length === 0) {
            return res.status(400).json({
                success: false,
                message: "OTP not verified",
            });
        }

        const customerResult = await pool.query(
            `
      SELECT customer_id
      FROM customers
      WHERE email = $1
         OR phone = $1
      `,
            [identifier]
        );

        if (customerResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Customer not found",
            });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        await pool.query(
            `
      UPDATE customers
      SET
        password = $1,
        updated_at = CURRENT_TIMESTAMP
      WHERE email = $2
         OR phone = $2
      `,
            [passwordHash, identifier]
        );

        await pool.query(
            `
      DELETE FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
      `,
            [identifier, PORTAL]
        );

        // Password changed - invalidate all existing refresh tokens for this user
        // so any other device/session gets logged out and must re-authenticate.
        await pool.query(
            `
      DELETE FROM refresh_tokens
      WHERE user_id = $1
        AND portal = $2
      `,
            [customerResult.rows[0].customer_id, PORTAL]
        );

        return res.status(200).json({
            success: true,
            message: "Password reset successfully",
        });
    } catch (err) {
        console.log("Reset Password Error :", err);

        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ==============================
// 7. REFRESH ACCESS TOKEN
// ==============================
exports.refreshAccessToken = async (req, res) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({
                success: false,
                message: "Refresh token required",
            });
        }

        const check = await verifyRefreshToken(refreshToken, PORTAL);

        if (!check.valid) {
            // expired or not found -> this device's session is over, must login again
            return res.status(401).json({
                success: false,
                message: "Session expired. Please login again.",
            });
        }

        const customerResult = await pool.query(
            `SELECT customer_id, is_blocked FROM customers WHERE customer_id = $1`,
            [check.userId]
        );

        if (customerResult.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Account not found",
            });
        }

        if (customerResult.rows[0].is_blocked) {
            return res.status(403).json({
                success: false,
                message: "Your account has been blocked",
            });
        }

        const accessToken = jwt.sign(
            { customer_id: check.userId },
            process.env.JWT_SECRET,
            { expiresIn: "1h" }
        );

        return res.status(200).json({
            success: true,
            accessToken,
        });
    } catch (err) {
        console.log("Refresh Token Error:", err);

        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ==============================
// 8. LOGOUT
// ==============================
exports.logout = async (req, res) => {
    try {
        const { refreshToken } = req.body;

        if (refreshToken) {
            await revokeRefreshToken(refreshToken, PORTAL);
        }

        return res.json({
            success: true,
            message: "Logout Successful",
        });
    } catch (err) {
        console.log("Logout Error:", err);
        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};