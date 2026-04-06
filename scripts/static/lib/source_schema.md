# Source Data Schema

This document defines the canonical fields the static site needs from each entity.

## Content files (`data/source/content/`)

### areas.json

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | integer | yes | primary key |
| slug | string | yes | URL-safe identifier |
| name | string | yes | display name |
| short_name | string | no | compact label for map |
| priority | integer | yes | sort weight |
| tags | array[string] | yes | e.g. `["popular","beginner_friendly"]` |
| description_fr | string | no | |
| description_en | string | no | |
| warning_fr | string | no | |
| warning_en | string | no | |
| published | boolean | yes | |
| cluster_id | integer | yes | FK to clusters |
| bounds | object | yes | `{ south_west: {lat, lng}, north_east: {lat, lng} }` |
| levels | object | yes | `{ "1": 12, "2": 34, ... "8": 5 }` problem counts per level |
| problems_count | integer | yes | total problems with location |

### problems.json

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | integer | yes | primary key |
| area_id | integer | yes | FK to areas |
| name | string | no | |
| name_en | string | no | English name when different |
| grade | string | no | e.g. `"7b"` |
| steepness | string | yes | wall/slab/overhang/roof/traverse/other |
| sit_start | boolean | yes | |
| location | object | no | `{ lat, lng }` — null means unpublished |
| circuit_id | integer | no | FK to circuits (simplified) |
| circuit_number | string | no | simplified (null for bis/ter/quater) |
| circuit_color | string | no | denormalized from circuit |
| featured | boolean | yes | |
| popularity | integer | no | |
| bleau_info_id | string | no | |
| parent_id | integer | no | FK to problems (variant parent) |

### circuits.json

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | integer | yes | primary key |
| color | string | yes | |
| average_grade | string | yes | |
| beginner_friendly | boolean | yes | |
| dangerous | boolean | yes | |
| risk | integer | no | |

### clusters.json

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | integer | yes | primary key |
| name | string | yes | |
| main_area_id | integer | yes | |

### pois.json

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | integer | yes | primary key |
| poi_type | string | yes | parking/train_station |
| name | string | yes | |
| short_name | string | yes | |
| google_url | string | yes | |
| location | object | yes | `{ lat, lng }` |

### poi_routes.json

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | integer | yes | primary key |
| area_id | integer | yes | FK to areas |
| poi_id | integer | yes | FK to pois |
| distance | integer | yes | raw distance in meters |
| transport | string | yes | walking/bike |

### topos.json

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | integer | yes | primary key |
| area_id | integer | yes | denormalized from first problem |
| published | boolean | yes | |
| photo_path | string | conditional | required when published |

### lines.json

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | integer | yes | primary key |
| problem_id | integer | yes | FK to problems |
| topo_id | integer | yes | FK to topos |
| coordinates | array | no | line overlay coordinates |

## Geometry files (`data/source/geojson/`)

GeoJSON FeatureCollections for map layers (areas, clusters, problems, circuits).
These are used by the map payload builder and are structured as standard GeoJSON.

## Media files (`data/source/media/`)

- `topos/area-<area_id>/topo-<topo_id>.jpg` — topo photos
- `area-covers/area-cover-<area_id>.jpg` — area cover images
