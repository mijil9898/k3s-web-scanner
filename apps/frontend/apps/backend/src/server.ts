import express from "express";
import cors from "cors";
import { Pool } from "pg";
import client from "prom-client";

const app = express();
const port = process.env.PORT || 8080;

// Prometheus metrics
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "5432"),
  database: process.env.DB_NAME || "mijil",
  user: process.env.DB_USER || "mijil",
  password: process.env.DB_PASSWORD,
});

app.use(cors());
app.use(express.json());

app.get("/health", (_, res) => res.json({ status: "ok" }));
app.get("/metrics", async (_, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.get("/api/projects", async (_, res) => {
  const { rows } = await pool.query("SELECT * FROM projects ORDER BY created_at DESC");
  res.json(rows);
});

app.listen(port, () => console.log(`Backend running on :${port}`));
