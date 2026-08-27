// const { Pool } = require("pg");

// const pool = new Pool({
//     user: "postgres",
//     host: "localhost",
//     database: "thiraa_db",
//     password: "Gowsi@21",
//     port: 5432,
// });

// pool.connect()
//   .then(client => {
//     console.log("PostgreSQL Connected");
//     client.release();
//   })
//   .catch(err => {
//     console.error("PostgreSQL Connection Error:", err.message);
//   });

// module.exports = pool;

const { Pool } = require("pg");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,

  // Render PostgreSQL connections use SSL.
  ssl: process.env.NODE_ENV === "production"
    ? { rejectUnauthorized: false }
    : false,
});

pool.connect()
  .then(client => {
    console.log("PostgreSQL Connected");
    client.release();
  })
  .catch(err => {
    console.error("PostgreSQL Connection Error:", err.message);
  });

module.exports = pool;