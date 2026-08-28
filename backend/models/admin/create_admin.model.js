const pool = require("../../config/db");

const findByUsername = async (username) => {
    const result = await pool.query(
        "SELECT * FROM admins WHERE username = $1",
        [username]
    );

    return result.rows[0];
};

const findByEmail = async (email) => {
    const result = await pool.query(
        "SELECT * FROM admins WHERE email = $1",
        [email]
    );

    return result.rows[0];
};

const createAdmin = async ({
    full_name,
    username,
    email,
    password_hash,
    role,
    is_active,
}) => {
    const result = await pool.query(
        `
    INSERT INTO admins
    (
      full_name,
      username,
      email,
      password_hash,
      role,
      is_active,
      created_at
    )
    VALUES
    ($1,$2,$3,$4,$5,$6,$7)
    RETURNING
      admin_id,
      full_name,
      username,
      email,
      role,
      is_active,
      created_at
    `,
        [
            full_name,
            username,
            email,
            password_hash,
            role,
            is_active,
            new Date(),
        ]
    );

    return result.rows[0];
};

module.exports = {
    findByUsername,
    findByEmail,
    createAdmin,
};