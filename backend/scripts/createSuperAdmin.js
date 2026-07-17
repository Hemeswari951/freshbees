require("dotenv").config();
const bcrypt = require("bcrypt");
const pool = require("../config/db");

async function createSuperAdmin() {
  try {

    const email = "jayasuryaparasu@gmail.com";

    // Already exists? 
    const existing = await pool.query(
      "SELECT admin_id FROM admins WHERE email = $1",
      [email]
    );

    if (existing.rows.length > 0) {
      console.log("✅ Super Admin already exists.");
      process.exit();
    }

    const passwordHash = await bcrypt.hash("Admin@123", 10);

    await pool.query(
      `
      INSERT INTO admins
      (username, email, password_hash, full_name, role)
      VALUES ($1, $2, $3, $4, $5)
      `,
      [
        "superadmin",
        email,
        passwordHash,
        "Super Admin",
        "SuperAdmin",
      ]
    );

    console.log("✅ Super Admin created successfully.");

    process.exit();

  } catch (err) {

    console.error(err);

    process.exit();

  }
}
  
createSuperAdmin();