const { Pool } = require("pg");

const pool = new Pool({
    user: "postgres",
    host: "localhost",
    database: "thiraa",
    password: "Surya@27",
    port: 5432,
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