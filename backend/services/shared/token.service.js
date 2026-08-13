const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const pool = require("../../config/db");

function hashToken(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

/**
 * Issues a new access token (1hr) + refresh token (30 days).
 * Stores the hashed refresh token in the shared refresh_tokens table.
 *
 * @param {number} userId - customer_id or shop_owner_id
 * @param {string} portal - 'customer' | 'shop_owner'
 * @param {object} jwtPayload - payload to sign into the access token, e.g. { customer_id } or { owner_id }
 */
async function issueTokens(userId, portal, jwtPayload) {
  const accessToken = jwt.sign(
    jwtPayload,
    process.env.JWT_SECRET,
    { expiresIn: "1h" }
  );

  const refreshToken = crypto.randomBytes(40).toString("hex");
  const tokenHash = hashToken(refreshToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

  await pool.query(
    `
    INSERT INTO refresh_tokens (user_id, portal, token_hash, expires_at)
    VALUES ($1, $2, $3, $4)
    `,
    [userId, portal, tokenHash, expiresAt]
  );

  return { accessToken, refreshToken };
}

/**
 * Verifies a refresh token for a given portal.
 * If expired, deletes the row (user must login again - "just logout" behavior).
 */
async function verifyRefreshToken(refreshToken, portal) {
  const tokenHash = hashToken(refreshToken);

  const result = await pool.query(
    `SELECT * FROM refresh_tokens WHERE token_hash = $1 AND portal = $2`,
    [tokenHash, portal]
  );

  if (result.rows.length === 0) {
    return { valid: false, reason: "not_found" };
  }

  const row = result.rows[0];

  if (new Date() > new Date(row.expires_at)) {
    await pool.query(
      `DELETE FROM refresh_tokens WHERE refresh_token_id = $1`,
      [row.refresh_token_id]
    );
    return { valid: false, reason: "expired" };
  }

  return { valid: true, userId: row.user_id };
}

/**
 * Deletes a refresh token (used on logout, or when rotating/replacing sessions).
 */
async function revokeRefreshToken(refreshToken, portal) {
  const tokenHash = hashToken(refreshToken);
  await pool.query(
    `DELETE FROM refresh_tokens WHERE token_hash = $1 AND portal = $2`,
    [tokenHash, portal]
  );
}

module.exports = {
  hashToken,
  issueTokens,
  verifyRefreshToken,
  revokeRefreshToken,
};