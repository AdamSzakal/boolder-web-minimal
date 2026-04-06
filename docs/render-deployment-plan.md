# Render.com Free Tier Deployment Plan

## Overview of challenges

- Production `database.yml` expects 4 separate PostgreSQL databases (primary, cache, queue, cable) — Render's free tier provides 1.
- The app uses the `postgis` adapter, but Render provides `postgres://` URLs (needs adapter swap in config).
- PostGIS extension must be enabled on the managed database.
- The Dockerfile exposes port 80 via Thruster — Render expects the app to bind to the `$PORT` env var (this works, Thruster respects `PORT`).

---

## Step 1 — Consolidate database config

Update `config/database.yml` to:
- Accept a single `DATABASE_URL` (what Render provides) for all four connections
- Rewrite the URL to use `postgis://` instead of `postgres://` so the adapter works

```yaml
production:
  primary:
    <<: *default
    url: <%= ENV["DATABASE_URL"]&.sub("postgres://", "postgis://") %>
  cache:
    <<: *default
    url: <%= ENV["DATABASE_URL"]&.sub("postgres://", "postgis://") %>
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    url: <%= ENV["DATABASE_URL"]&.sub("postgres://", "postgis://") %>
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    url: <%= ENV["DATABASE_URL"]&.sub("postgres://", "postgis://") %>
    migrations_paths: db/cable_migrate
```

This removes the need for `DB_HOST` and `POSTGRES_PASSWORD` env vars.

## Step 2 — Add a migration to enable PostGIS

Render's managed PostgreSQL supports PostGIS but it must be explicitly enabled. Add a migration:

```ruby
# db/migrate/YYYYMMDDHHMMSS_enable_postgis.rb
class EnablePostgis < ActiveRecord::Migration[8.0]
  def up
    execute "CREATE EXTENSION IF NOT EXISTS postgis"
  end
  def down
    execute "DROP EXTENSION IF EXISTS postgis"
  end
end
```

This will run automatically during `db:prepare` on first deploy.

## Step 3 — Create `render.yaml`

Add an infrastructure-as-code file at the repo root to define the web service and database declaratively:

```yaml
services:
  - type: web
    name: boolder
    runtime: docker
    plan: free
    envVars:
      - key: RAILS_MASTER_KEY
        sync: false          # paste manually in the dashboard
      - key: SOLID_QUEUE_IN_PUMA
        value: "true"        # run background jobs inside the web process (no separate worker)
      - key: RAILS_LOG_TO_STDOUT
        value: "enabled"
    healthCheckPath: /up     # Rails 8 built-in health endpoint

databases:
  - name: boolder-db
    plan: free
    databaseName: boolder_production
    postgresMajorVersion: 16
```

The `DATABASE_URL` will be automatically injected by Render when the database is linked to the web service.

## Step 4 — Set environment variables in Render dashboard

After connecting the repo, set these in the Render dashboard under **Environment**:

| Variable | Value |
|---|---|
| `RAILS_MASTER_KEY` | contents of `config/master.key` |
| `SOLID_QUEUE_IN_PUMA` | `true` |
| `RAILS_LOG_TO_STDOUT` | `enabled` |

Optional (only if S3 file storage is needed):
- `S3_READONLY_KEY`
- `S3_READONLY_SECRET`

The `DATABASE_URL` is injected automatically — do not set it manually.

## Step 5 — Connect and deploy on Render

1. Create a Render account at render.com
2. Click **New → Web Service**, connect your GitHub repo
3. Render will detect the `Dockerfile` automatically
4. Link the PostgreSQL database created via `render.yaml` (or create it manually in the dashboard)
5. Confirm environment variables are set
6. Click **Deploy**

On first deploy, `docker-entrypoint` runs `rails db:prepare`, which will run all migrations
(including enabling PostGIS) and seed if needed.

---

## Free tier limitations

| Limitation | Impact |
|---|---|
| Web service spins down after 15 min inactivity | First request after idle takes ~30s |
| Free PostgreSQL expires after **90 days** | Must re-create or upgrade before expiry |
| 512 MB RAM | Solid Queue + PostGIS queries are memory-intensive — monitor usage |
| No persistent disk | Any files written locally (not S3) are lost on redeploy |
| One free PostgreSQL instance | All 4 Rails "databases" share one physical DB (covered in Step 1) |

---

## Code changes required

1. `config/database.yml` — consolidate to `DATABASE_URL` with `postgis://` rewrite ✓
2. `db/migrate/..._enable_postgis.rb` — migration to enable the extension ✓
3. `render.yaml` — service definition at repo root ✓
