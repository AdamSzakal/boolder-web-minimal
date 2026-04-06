# Source Data

This directory contains the file-backed dataset that powers the static Boolder site.
All files here serve as the single source of truth — no database is required at runtime.

## Directory layout

```
data/source/
├── content/          # Non-geometry metadata (JSON)
│   ├── areas.json
│   ├── problems.json
│   ├── circuits.json
│   ├── clusters.json
│   ├── pois.json
│   ├── poi_routes.json
│   ├── topos.json
│   └── lines.json
├── geojson/          # Geometry-heavy data (GeoJSON FeatureCollections)
│   ├── areas.geojson
│   ├── clusters.geojson
│   ├── problems.geojson
│   └── circuits.geojson
└── media/            # Exported image assets
    ├── topos/        # area-<id>/topo-<id>.jpg
    └── area-covers/  # area-cover-<id>.jpg
```

## Source-of-truth split

| Kind | Format | Location |
|------|--------|----------|
| Geometry-heavy data | GeoJSON | `data/source/geojson/` |
| Non-geometry metadata | JSON arrays | `data/source/content/` |
| Media assets | JPG files | `data/source/media/` |

## Updating source files

Source files are exported from the Rails database using rake tasks (during the
transition period) or edited directly. After updating, rebuild the static site:

```bash
ruby scripts/static/build.rb
```

## Schema reference

See `scripts/static/lib/source_schema.md` for the full field inventory.
