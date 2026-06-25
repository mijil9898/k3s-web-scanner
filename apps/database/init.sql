CREATE TABLE IF NOT EXISTS projects (
  id          SERIAL PRIMARY KEY,
  title       VARCHAR(255) NOT NULL,
  description TEXT,
  tech_stack  TEXT[],
  github_url  VARCHAR(500),
  demo_url    VARCHAR(500),
  created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS contacts (
  id         SERIAL PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  email      VARCHAR(255) NOT NULL,
  message    TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Bảng lưu lịch sử phân tích malware
CREATE TABLE IF NOT EXISTS malware_analyses (
  id            SERIAL PRIMARY KEY,
  analysis_id   UUID NOT NULL UNIQUE,
  filename      VARCHAR(500) NOT NULL,
  file_type     VARCHAR(200),
  sha256        VARCHAR(64),
  md5           VARCHAR(32),
  risk_score    INTEGER DEFAULT 0,
  risk_level    VARCHAR(20) DEFAULT 'UNKNOWN',
  yara_matches  TEXT[],          -- danh sách rule YARA matched
  mitre_ids     TEXT[],          -- danh sách kỹ thuật MITRE ATT&CK
  has_errors    BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_malware_analyses_created_at ON malware_analyses (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_malware_analyses_risk_level  ON malware_analyses (risk_level);
CREATE INDEX IF NOT EXISTS idx_malware_analyses_sha256       ON malware_analyses (sha256);

-- Bảng lưu training samples cho ML model (features + VT oracle labels)
CREATE TABLE IF NOT EXISTS ml_training_samples (
  id               SERIAL PRIMARY KEY,
  analysis_id      UUID,
  sha256           VARCHAR(64) UNIQUE,          -- dedup theo file hash
  features         JSONB NOT NULL,              -- feature vector từ ml_features.extract()
  label            SMALLINT NOT NULL CHECK (label IN (0, 1)), -- 0=clean, 1=malicious
  malware_family   VARCHAR(200),                -- tên family từ VT (nếu có)
  source           VARCHAR(50) DEFAULT 'virustotal', -- nguồn label
  used_in_training BOOLEAN DEFAULT FALSE,       -- đã dùng trong lần retrain nào chưa
  created_at       TIMESTAMP DEFAULT NOW(),
  updated_at       TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ml_samples_label       ON ml_training_samples (label);
CREATE INDEX IF NOT EXISTS idx_ml_samples_used        ON ml_training_samples (used_in_training);
CREATE INDEX IF NOT EXISTS idx_ml_samples_created_at  ON ml_training_samples (created_at DESC);

INSERT INTO projects (title, description, tech_stack)
VALUES
  ('k3s-mijil-platform', 'Full-stack K8s deployment',
   ARRAY['K3s','Docker','Helm','GitHub Actions'])
ON CONFLICT DO NOTHING;
