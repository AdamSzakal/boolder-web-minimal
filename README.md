# Boolder Static Site

A static site for discovering bouldering in Fontainebleau, built from the open data provided by the [Boolder](https://www.boolder.com) project.

This project is a lightweight, database-free rebuild of the public-facing parts of the Boolder website. It takes exported JSON data and generates a fully static site that can be hosted on any file server or CDN.

## Based on

- [boolder-org/boolder](https://github.com/boolder-org/boolder) — the original Rails application powering boolder.com
- [boolder-org/boolder-data](https://github.com/boolder-org/boolder-data) — the open dataset of 19,000+ bouldering problems in Fontainebleau

Topo photos are served from the Boolder CDN (`assets.boolder.com`). Map tiles are hosted on Mapbox using the original Boolder tileset and style.

## What's included

- **Area pages** — 90 climbing areas with descriptions, circuits, popular problems, and access info
- **Problem pages** — 19,000+ individual boulder problems with topo photos and SVG line overlays
- **Circuit pages** — 270+ color-coded circuits with sorted problem lists
- **Interactive map** — Mapbox GL JS with area/problem deep links and grade filtering
- **Search** — client-side search over areas and problems (accent-insensitive)
- **Boulders browser** — filterable/sortable list by grade, steepness, and popularity
- **Project lists** — problem bookmarks stored in localStorage, shareable via URL

## Stack

- Ruby 3.3 (build scripts only, no runtime server)
- ERB templates with Tailwind CSS
- Mapbox GL JS for the map
- Vanilla JavaScript for search, filtering, and project lists
- Static JSON for all data

## Quick start

### Prerequisites

- Ruby 3.3+ (`brew install rbenv && rbenv install 3.3.5`)
- `sqlite3` gem (`gem install sqlite3`) — only needed for data import

### Build

```bash
ruby scripts/static/build.rb
```

This reads source data from `data/source/content/` and generates a deployable `dist/` directory.

### Preview locally

```bash
python3 -m http.server 4173 --directory dist
```

Then open http://localhost:4173/en/fontainebleau

### Deploy

```bash
rsync -av dist/ <your-static-host>
```

## Refreshing the data

Source data lives under `data/source/content/` as JSON files, imported from the [boolder-data](https://github.com/boolder-org/boolder-data) SQLite database. This is the canonical open dataset maintained by the Boolder project.

To update to the latest data:

```bash
# Clone or pull the data repo (one-time setup)
git clone https://github.com/boolder-org/boolder-data.git ../boolder-data

# Import into source JSON
ruby scripts/static/import_from_boolder_data.rb ../boolder-data/boolder.db

# Rebuild the site
ruby scripts/static/build.rb
```

The import script converts the SQLite tables into the JSON format expected by the build, deriving slugs for URLs and resolving circuit-area relationships.

A legacy `bin/rails static:export` rake task also exists for exporting from the original Rails database, but the boolder-data import is preferred as it has more complete and up-to-date data.

## Project structure

```
data/source/content/     — exported JSON (areas, problems, circuits, topos, lines, etc.)
scripts/static/build.rb  — single entry point that generates dist/
scripts/static/lib/       — build modules (catalog, read models, renderer, search, media, map)
scripts/static/templates/ — ERB page templates
test/static/              — tests for build modules
dist/                     — generated output (gitignored)
```
