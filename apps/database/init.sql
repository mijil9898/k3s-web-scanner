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

INSERT INTO projects (title, description, tech_stack)
VALUES
  ('k3s-mijil-platform', 'Full-stack K8s deployment',
   ARRAY['K3s','Docker','Helm','GitHub Actions'])
ON CONFLICT DO NOTHING;
