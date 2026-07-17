const pool = require('../../config/db');

async function findAll() {
  const { rows } = await pool.query(
    `SELECT category_id, category_name FROM categories ORDER BY category_name`
  );
  return rows;
}

module.exports = { findAll };
