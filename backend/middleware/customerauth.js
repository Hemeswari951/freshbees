const jwt = require("jsonwebtoken");
const pool = require('../config/db');
 
module.exports = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
 
    if (
      !authHeader ||
      !authHeader.startsWith("Bearer ")
    ) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }
 
    const token = authHeader.split(" ")[1];
 
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
        message: "Customer not found",
      });
    }
 
    const customer = result.rows[0];
 
    if (customer.is_blocked) {
      return res.status(403).json({
        success: false,
        message: "Your account has been blocked.",
      });
    }
 
    // Map properties to match what your order controller expects (customerId)
    req.customer = {
      customerId: customer.customer_id,
      firstName: customer.first_name,
      lastName: customer.last_name,
      email: customer.email,
      phone: customer.phone,
    };
 
    next();
 
  } catch (err) {
 
    console.log("Customer Auth Error:", err);
 
    return res.status(401).json({
      success: false,
      message: "Invalid or Expired Token",
    });
 
  }
};
 