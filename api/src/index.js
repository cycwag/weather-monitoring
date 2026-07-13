const express = require("express");
const redis = require("./redisClient");
const db = require("./dbClient");

const app = express();
const PORT = process.env.PORT || 3000;

app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET");
  next();
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

// === Endpoint: Ambil cuaca terkini sebuah kota ===
// Alur: cek Redis dulu (cache) -> kalau tidak ada, ambil dari PostgreSQL (data terakhir)
app.get("/weather", async (req, res) => {
  const city = req.query.city;

  if (!city) {
    return res.status(400).json({ error: "Query parameter 'city' wajib diisi" });
  }

  try {
    // 1. Cek cache Redis dulu
    const cached = await redis.get(`weather:${city.toLowerCase()}`);
    if (cached) {
      return res.status(200).json({ source: "cache", data: JSON.parse(cached) });
    }

    // 2. Kalau tidak ada di cache, ambil data terakhir dari PostgreSQL
    const result = await db.query(
      `SELECT city, temperature, humidity, description, recorded_at
       FROM weather_history
       WHERE LOWER(city) = LOWER($1)
       ORDER BY recorded_at DESC
       LIMIT 1`,
      [city]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: `Belum ada data cuaca untuk kota '${city}'` });
    }

    return res.status(200).json({ source: "database", data: result.rows[0] });
  } catch (err) {
    console.error("[GET /weather] error:", err.message);
    return res.status(500).json({ error: "Terjadi kesalahan di server" });
  }
});

// === Endpoint: Ambil history cuaca sebuah kota ===
app.get("/weather/history", async (req, res) => {
  const city = req.query.city;
  const limit = parseInt(req.query.limit) || 24; // default 24 data terakhir

  if (!city) {
    return res.status(400).json({ error: "Query parameter 'city' wajib diisi" });
  }

  try {
    const result = await db.query(
      `SELECT city, temperature, humidity, description, recorded_at
       FROM weather_history
       WHERE LOWER(city) = LOWER($1)
       ORDER BY recorded_at DESC
       LIMIT $2`,
      [city, limit]
    );

    return res.status(200).json({ city, count: result.rows.length, data: result.rows });
  } catch (err) {
    console.error("[GET /weather/history] error:", err.message);
    return res.status(500).json({ error: "Terjadi kesalahan di server" });
  }
});

app.listen(PORT, () => {
  console.log(`[api] weather-api listening on port ${PORT}`);
});
