import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { Pool } from "pg";
import * as promClient from "prom-client";

const app = express();
const port = process.env.PORT || 8080;

// Security: Helmet sets various HTTP headers
app.use(helmet());

// Security: Rate Limiting
const limiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // limit each IP to 100 requests per windowMs
  message: { error: "Too many requests, please try again later." },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use("/api/", limiter);

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "5432"),
  database: process.env.DB_NAME || "mijil",
  user: process.env.DB_USER || "mijil",
  password: process.env.DB_PASSWORD,
});

// Security: Strict CORS
const allowedOrigins = [
  "https://mijil.yourdomain.com",
  process.env.FRONTEND_URL,
].filter(Boolean);

app.use(cors({
  origin: function (origin, callback) {
    if (!origin || allowedOrigins.includes(origin) || process.env.NODE_ENV !== "production") {
      callback(null, true);
    } else {
      callback(new Error("Not allowed by CORS"));
    }
  }
}));

app.use(express.json({ limit: '1mb' })); // Security: Limit JSON body payload

app.get("/health", (_, res) => res.json({ status: "ok" }));

app.get("/metrics", async (_, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.get("/api/projects", async (_, res) => {
  try {
    const { rows } = await pool.query("SELECT * FROM projects ORDER BY created_at DESC");
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: "Database error" });
  }
});

app.post("/api/contact", async (req, res) => {
  const { name, email, message } = req.body;
  if (!name || !email || !message) {
    return res.status(400).json({ error: "name, email, and message are required" });
  }
  if (typeof name !== "string" || typeof email !== "string" || typeof message !== "string") {
    return res.status(400).json({ error: "Invalid input types" });
  }
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: "Invalid email format" });
  }
  try {
    await pool.query(
      "INSERT INTO contacts (name, email, message) VALUES ($1, $2, $3)",
      [name.slice(0, 100), email.slice(0, 255), message.slice(0, 5000)]
    );
    res.json({ success: true, message: "Contact saved successfully" });
  } catch (err) {
    res.status(500).json({ error: "Database error" });
  }
});

app.listen(port, () => console.log(`Backend running on :${port}`));
