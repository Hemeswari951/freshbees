const pool = require("../../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require('crypto');
const { sendOtpMail } = require('../../services/shared/sendotpmail.service');

// Helper to check if identifier is a phone number
function isPhone(identifier) {
  return /^[0-9]{10}$/.test(identifier.replace(/\D/g, '').slice(-10));
}

// 1. SEND OTP
exports.sendOtp = async (req, res) => {
  try {
    const identifier = (req.body.identifier || "")
      .toString()
      .trim()
      .toLowerCase();
 
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
    if (!purpose || purpose === 'auth') {
      purpose = isNewUser ? "registration" : "login";
    }
 
    // Generate 6-digit OTP
    const otp = crypto.randomInt(100000, 999999).toString();
    const hashedOtp = await bcrypt.hash(otp, 10);
    const expiresAt = new Date(Date.now() + 2 * 60 * 1000); // 2 Minutes Expiry
 
    // Delete previous OTP for this identifier & portal (Re-send Logic)
    await pool.query(
      `
      DELETE FROM otp_verifications
      WHERE identifier = $1
      AND portal = $2
      `,
      [identifier, "customer"]
    );
 
    // Save new OTP
    await pool.query(
      `
      INSERT INTO otp_verifications
      (
        identifier,
        portal,
        purpose,
        otp_code,
        expires_at
      )
      VALUES
      ($1, $2, $3, $4, $5)
      `,
      [
        identifier,
        "customer",
        purpose,
        hashedOtp,
        expiresAt,
      ]
    );

    // Terminal Logging for Testing
    console.log("=========================================");
    console.log(`📱 Identifier       : ${identifier}`);
    console.log(`🔑 Generated OTP   : ${otp}`);
    console.log(`🎯 Portal & Purpose: customer | ${purpose}`);
    console.log("=========================================");
 
    // Send OTP via SMS or Mail
    if (isPhone(identifier)) {
      // await sendOtpSms(identifier, otp);
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

// 2. VERIFY OTP
exports.verifyOtp = async (req, res) => {
  try {
    const { identifier, otp } = req.body;
 
    if (!otp) {
      return res.status(400).json({
        success: false,
        message: "OTP is required",
      });
    }
 
    // Get OTP record
    const otpResult = await pool.query(
      `
      SELECT *
      FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
      `,
      [identifier.toLowerCase(), "customer"]
    );
 
    if (otpResult.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: "OTP not found. Please request a new OTP",
      });
    }
 
    const otpRow = otpResult.rows[0];
 
    // Check Expired
    if (new Date() > new Date(otpRow.expires_at)) {
      return res.status(400).json({
        success: false,
        message: "OTP expired. Please request a new OTP",
      });
    }
 
    // Check Max Attempts
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
        [identifier.toLowerCase(), "customer"]
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
      [identifier.toLowerCase(), "customer"]
    );
 
    // Check Customer status
    const customerResult = await pool.query(
      `
      SELECT *
      FROM customers
      WHERE email = $1
         OR phone = $1
      `,
      [identifier.toLowerCase()]
    );
 
    // NEW USER
    if (customerResult.rows.length === 0) {
      return res.status(200).json({
        success: true,
        isNewUser: true,
        message: "OTP verified successfully",
      });
    }
 
    // EXISTING USER
    const customer = customerResult.rows[0];
 
    if (customer.is_blocked) {
      return res.status(403).json({
        success: false,
        message: "Your account has been blocked.",
      });
    }
 
    // Generate JWT Token
    const token = jwt.sign(
      { customer_id: customer.customer_id },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );
 
    // Update Last Login
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
      token,
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

// 3. REGISTER
exports.register = async (req, res) => {
  try {
    const {
      identifier,
      password,
      first_name,
      last_name,
      gender,
      date_of_birth,
    } = req.body;
 
    if (
      !identifier ||
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
 
    const otpResult = await pool.query(
      `
      SELECT *
      FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
        AND is_verified = true
      `,
      [identifier.toLowerCase(), "customer"]
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
      [identifier.toLowerCase()]
    );
 
    if (existingCustomer.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: "Customer already exists",
      });
    }
 
    const passwordHash = await bcrypt.hash(password, 10);
    const isEmail = identifier.includes("@");

    const customerEmail = isEmail ? identifier.toLowerCase() : null;
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
      [identifier.toLowerCase(), "customer"]
    );
 
    const token = jwt.sign(
      { customer_id: customer.customer_id },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );
 
    return res.status(201).json({
      success: true,
      message: "Registration Successful",
      token,
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

// 4. LOGIN
exports.login = async (req, res) => {
  try {
    const { identifier, password } = req.body;
 
    if (!identifier || !password) {
      return res.status(400).json({
        success: false,
        message: "Identifier and password are required",
      });
    }
 
    const result = await pool.query(
      `
      SELECT *
      FROM customers
      WHERE email = $1
         OR phone = $1
      `,
      [identifier.toLowerCase()]
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
 
    const token = jwt.sign(
      { customer_id: customer.customer_id },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
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
      token,
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

// 5. FORGOT PASSWORD
exports.forgotPassword = async (req, res) => {
  try {
    const { identifier } = req.body;
 
    if (!identifier) {
      return res.status(400).json({
        success: false,
        message: "Mobile number or Email is required",
      });
    }
 
    const result = await pool.query(
      `
      SELECT customer_id, email, phone
      FROM customers
      WHERE email = $1
         OR phone = $1
      `,
      [identifier.toLowerCase()]
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
      [identifier.toLowerCase(), "customer"]
    );
 
    await pool.query(
      `
      INSERT INTO otp_verifications
      (
        identifier,
        portal,
        purpose,
        otp_code,
        expires_at
      )
      VALUES
      ($1, $2, $3, $4, $5)
      `,
      [
        identifier.toLowerCase(),
        "customer",
        "forgot_password",
        hashedOtp,
        expiresAt,
      ]
    );

    console.log("=========================================");
    console.log(`📱 Identifier       : ${identifier.toLowerCase()}`);
    console.log(`🔑 Generated OTP   : ${otp}`);
    console.log(`🎯 Portal & Purpose: customer | forgot_password`);
    console.log("=========================================");
 
    if (isPhone(identifier)) {
      // await sendOtpSms(identifier, otp);
    } else {
      await sendOtpMail({
        toEmail: identifier.toLowerCase(),
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

// 6. RESET PASSWORD
exports.resetPassword = async (req, res) => {
  try {
    const { identifier, password } = req.body;
 
    if (!identifier || !password) {
      return res.status(400).json({
        success: false,
        message: "Identifier and password are required",
      });
    }
 
    const otpResult = await pool.query(
      `
      SELECT *
      FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
        AND is_verified = true
      `,
      [identifier.toLowerCase(), "customer"]
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
      [identifier.toLowerCase()]
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
      [passwordHash, identifier.toLowerCase()]
    );
 
    await pool.query(
      `
      DELETE FROM otp_verifications
      WHERE identifier = $1
        AND portal = $2
      `,
      [identifier.toLowerCase(), "customer"]
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

// 7. LOGOUT
exports.logout = async (req, res) => {
  try {
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