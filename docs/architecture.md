# Architecture

## Purpose

`haderach-content` holds the static documentation pages served at
[docs.haderach.ai](https://docs.haderach.ai). It does not contain application
logic — the serving layer (`content-api`) lives in `haderach-platform`.

## Repository Tree

```text
haderach-content/
├── .cursor/
│   └── rules/
│       └── deploy-workflow.mdc
├── .github/
│   └── workflows/
│       └── ci.yml               # PR checks (no build step)
├── docs/
│   └── architecture.md          # This file
├── public/
│   ├── index.html               # Landing page
│   ├── overview.html            # Platform overview — features and benefits
│   ├── user-guide.html          # User guide — how-to instructions
│   ├── api-docs/                # API reference docs (ReDoc + live OpenAPI)
│   │   ├── index.html
│   │   ├── agent-api.html
│   │   ├── vendors-api.html
│   │   └── stocks-api.html
│   └── db-schema/               # SchemaSpy-generated database documentation
└── README.md
```

## Ownership Boundaries

### This repo owns

- All static content files served at `docs.haderach.ai`.
- Content structure and navigation (index page, section pages).
- SchemaSpy database documentation snapshots.
- API reference pages (ReDoc wrappers that fetch live OpenAPI specs).

### This repo does NOT own

- The `content-api` Cloud Run service (lives in `haderach-platform/services/content-api/`).
- Infrastructure (Terraform in `haderach-platform/infra/content-api.tf`).
- The deploy workflow (lives in `haderach-platform/.github/workflows/deploy-content.yml`).
- Authentication logic (handled by `content-api` via Google OAuth + Postgres user whitelist).

## Serving Architecture

```text
Browser → docs.haderach.ai (Cloud Run: content-api)
              │
              ├── Google OAuth login
              ├── Session cookie validation
              ├── User whitelist check (Postgres users table)
              │
              └── Serves files from GCS bucket (haderach-content-docs)
```

- **Cloud Run service** (`content-api`): handles authentication, then proxies
  file requests to the GCS bucket. No caching layer — files are served directly
  from GCS on every request.
- **GCS bucket** (`haderach-content-docs`): stores the contents of `public/`.
  Updated via `gsutil rsync` during deployment.
- **Custom domain**: `docs.haderach.ai` is mapped to the Cloud Run service
  with automatic SSL certificate provisioning.

## Deployment Flow

```text
Feature branch → PR → Merge to main → Manual workflow trigger → GCS sync → Live
```

1. Create a feature branch and edit files in `public/`.
2. Push and open a PR. The `ci.yml` workflow runs (no build step — static content only).
3. Merge to `main`.
4. Go to `haderach-platform` repo → Actions → `deploy-content` → Run workflow → select environment.
5. The workflow checks out this repo at HEAD, authenticates to GCP via WIF,
   and runs `gsutil -m rsync -r -d public/ gs://<CONTENT_BUCKET>/`.
6. Changes are live on `docs.haderach.ai` immediately — no cache or build step.

### Important

- **Never deploy directly.** Do not run `gsutil` or `gcloud storage` commands
  manually. All changes go through the PR and workflow process.
- **No automatic deploy on merge.** The `deploy-content` workflow is
  `workflow_dispatch` only — you must trigger it manually after merging.

## Content Types

### Static HTML pages (overview, user guide)

Hand-authored HTML files. The `content-api` service supports extensionless URLs
(e.g., `/overview` resolves to `overview.html`).

### API reference (api-docs/)

Lightweight HTML pages that load [ReDoc](https://github.com/Redocly/redoc) from
a CDN and point it at the live `/openapi.json` endpoint of each Cloud Run API
service. No static spec files are stored — documentation always reflects the
currently deployed API.

### Database schema (db-schema/)

SchemaSpy-generated HTML documentation. These are static snapshots and must be
regenerated and committed when the database schema changes.

## Infrastructure Reference

All infrastructure is managed in the `haderach-platform` repo:

| Resource | Terraform file | Purpose |
|---|---|---|
| GCS bucket (`haderach-content-docs`) | `infra/content-api.tf` | Static file storage |
| Cloud Run service (`content-api`) | `infra/content-api.tf` | Auth + file serving |
| Domain mapping (`docs.haderach.ai`) | `infra/content-api.tf` | Custom domain + SSL |
| OAuth secrets | `infra/content-api.tf` | Client ID/secret, session key |
| Cloud Scheduler warm-up | `infra/content-api.tf` | Keeps service warm |
| Deploy workflow | `.github/workflows/deploy-content.yml` | GCS sync |

## Cross-Repo Dependencies

| Dependency | Repo | What it provides |
|---|---|---|
| `content-api` service | `haderach-platform` | Authentication and file serving |
| `deploy-content` workflow | `haderach-platform` | Deployment pipeline |
| Postgres `users` table | `agent` (migrations) | User whitelist for auth |
| OpenAPI specs | `agent`, `vendors`, `stocks` | Live API documentation |
| CORS middleware | `agent`, `vendors`, `stocks` | Allows ReDoc to fetch specs from `docs.haderach.ai` |
