const pool = require('../../config/db');

async function findAll() {
  const { rows } = await pool.query(
    `SELECT brand_id, brand_name FROM brands ORDER BY brand_name`
  );
  return rows;
}

module.exports = { findAll };
