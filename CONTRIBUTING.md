# Contributing to Web-Scan

We love your input! We want to make contributing to this project as easy and transparent as possible.

## Development Process
1. Clone the repository.
2. Ensure you have Docker, Docker Compose, and Make installed.
3. Run `make dev` to spin up the local development environment (Frontend, Backend, Malware Analyzer, Postgres, Neo4j).
4. Make your changes in a new branch.
5. Run `make test` to ensure all tests and linters pass.
6. Submit a Pull Request.

## Coding Style
- **Python**: We use `black`, `flake8`, and `ruff` for formatting and linting.
- **Node.js**: We use `prettier` and `eslint`.
- **Docker**: We use `hadolint` for Dockerfiles.

## Pull Request Process
1. Ensure your PR is against the `main` branch.
2. Update `README.md` and `CHANGELOG.md` with details of changes.
3. Your PR will require at least one approval from a maintainer to be merged.
