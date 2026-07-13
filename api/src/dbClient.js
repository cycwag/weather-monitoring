const { Pool } = require("pg");

const pool = new Pool({
  host: process.env.DB_HOST || "postgres",
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || "weather_user",
  password: process.env.DB_PASSWORD || "weather_pass",
  database: process.env.DB_NAME || "weather_db",
});

pool.on("connect", () => {
  console.log("[postgres] connected");
});

pool.on("error", (err) => {
  console.error("[postgres] error:", err.message);
});

module.exports = pool;