#!/usr/bin/env ruby
# Imports data from the boolder-data SQLite database into data/source/content/*.json
# Usage: ruby scripts/static/import_from_boolder_data.rb [path/to/boolder.db]

require "json"
require "sqlite3"
require "fileutils"

db_path = ARGV[0] || File.expand_path("../../boolder-data/boolder.db", __dir__)
unless File.exist?(db_path)
  abort "Database not found at #{db_path}. Clone https://github.com/boolder-org/boolder-data next to this repo, or pass the path as an argument."
end

output_dir = File.expand_path("../../data/source/content", __dir__)
FileUtils.mkdir_p(output_dir)

db = SQLite3::Database.new(db_path)
db.results_as_hash = true

def slugify(name)
  name.unicode_normalize(:nfkd)
      .gsub(/[\u0300-\u036f]/, "")
      .downcase
      .gsub(/[^a-z0-9]+/, "-")
      .gsub(/^-|-$/, "")
end

def write_json(dir, filename, records)
  File.write(File.join(dir, filename), JSON.pretty_generate(records))
  puts "  #{filename}: #{records.size} records"
end

# --- Areas ---
areas = db.execute("SELECT * FROM areas ORDER BY id").map do |a|
  {
    "id" => a["id"],
    "slug" => slugify(a["name"]),
    "name" => a["name"],
    "short_name" => a["name"],
    "priority" => a["priority"],
    "tags" => a["tags"] ? a["tags"].split(",") : [],
    "description_fr" => a["description_fr"],
    "description_en" => a["description_en"],
    "warning_fr" => a["warning_fr"],
    "warning_en" => a["warning_en"],
    "published" => true,
    "cluster_id" => a["cluster_id"],
    "south_west_lat" => a["south_west_lat"],
    "south_west_lng" => a["south_west_lon"],
    "north_east_lat" => a["north_east_lat"],
    "north_east_lng" => a["north_east_lon"],
    "problems_count" => a["problems_count"],
    "name_searchable" => a["name_searchable"],
    "level1_count" => a["level1_count"],
    "level2_count" => a["level2_count"],
    "level3_count" => a["level3_count"],
    "level4_count" => a["level4_count"],
    "level5_count" => a["level5_count"],
    "level6_count" => a["level6_count"],
    "level7_count" => a["level7_count"],
    "level8_count" => a["level8_count"],
  }
end
write_json(output_dir, "areas.json", areas)

# --- Problems ---
problems = db.execute("SELECT * FROM problems ORDER BY id").map do |p|
  {
    "id" => p["id"],
    "area_id" => p["area_id"],
    "name" => p["name_en"].to_s.empty? ? p["name"] : p["name_en"],
    "name_searchable" => p["name_searchable"],
    "grade" => p["grade"],
    "steepness" => p["steepness"],
    "sit_start" => p["sit_start"] == 1,
    "location" => { "lat" => p["latitude"], "lng" => p["longitude"] },
    "circuit_id" => p["circuit_id"],
    "circuit_number" => p["circuit_number"],
    "circuit_color" => p["circuit_color"],
    "featured" => p["featured"] == 1,
    "popularity" => p["popularity"],
    "bleau_info_id" => p["bleau_info_id"],
    "parent_id" => p["parent_id"]
  }
end
write_json(output_dir, "problems.json", problems)

# --- Circuits (derive main_area from most common area in circuit's problems) ---
# Build area lookup for main_area_name
area_names = areas.each_with_object({}) { |a, h| h[a["id"]] = a["name"] }

# Find most common area_id per circuit
circuit_main_areas = {}
db.execute("SELECT circuit_id, area_id, COUNT(*) as cnt FROM problems WHERE circuit_id IS NOT NULL GROUP BY circuit_id, area_id ORDER BY circuit_id, cnt DESC").each do |row|
  circuit_main_areas[row["circuit_id"]] ||= row["area_id"]
end

circuits = db.execute("SELECT * FROM circuits ORDER BY id").map do |c|
  main_area_id = circuit_main_areas[c["id"]]
  {
    "id" => c["id"],
    "color" => c["color"],
    "average_grade" => c["average_grade"],
    "beginner_friendly" => c["beginner_friendly"] == 1,
    "dangerous" => c["dangerous"] == 1,
    "main_area_id" => main_area_id,
    "main_area_name" => main_area_id ? area_names[main_area_id] : nil,
    "south_west_lat" => c["south_west_lat"],
    "south_west_lng" => c["south_west_lon"],
    "north_east_lat" => c["north_east_lat"],
    "north_east_lng" => c["north_east_lon"]
  }
end
write_json(output_dir, "circuits.json", circuits)

# --- Clusters ---
clusters = db.execute("SELECT * FROM clusters ORDER BY id").map do |c|
  {
    "id" => c["id"],
    "name" => c["name"],
    "main_area_id" => c["main_area_id"]
  }
end
write_json(output_dir, "clusters.json", clusters)

# --- POIs ---
pois = db.execute("SELECT * FROM pois ORDER BY id").map do |p|
  {
    "id" => p["id"],
    "poi_type" => p["poi_type"],
    "name" => p["name"],
    "short_name" => p["short_name"],
    "google_url" => p["google_url"],
    "location" => { "lat" => p["latitude"], "lng" => p["longitude"] }
  }
end
write_json(output_dir, "pois.json", pois)

# --- POI Routes ---
poi_routes = db.execute("SELECT * FROM poi_routes ORDER BY id").map do |pr|
  {
    "id" => pr["id"],
    "area_id" => pr["area_id"],
    "poi_id" => pr["poi_id"],
    "distance_in_minutes" => pr["distance_in_minutes"],
    "transport" => pr["transport"]
  }
end
write_json(output_dir, "poi_routes.json", poi_routes)

# --- Topos ---
topos = db.execute("SELECT * FROM topos ORDER BY id").map do |t|
  {
    "id" => t["id"],
    "area_id" => t["area_id"],
    "boulder_id" => t["boulder_id"],
    "position" => t["position"],
    "published" => true
  }
end
write_json(output_dir, "topos.json", topos)

# --- Lines ---
lines = db.execute("SELECT * FROM lines ORDER BY id").map do |l|
  coords = l["coordinates"]
  parsed = (coords && coords != "null") ? JSON.parse(coords) : nil
  {
    "id" => l["id"],
    "problem_id" => l["problem_id"],
    "topo_id" => l["topo_id"],
    "coordinates" => parsed
  }
end
write_json(output_dir, "lines.json", lines)

puts "Done! All source JSON written to #{output_dir}"
