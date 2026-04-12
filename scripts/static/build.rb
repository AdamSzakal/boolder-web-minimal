#!/usr/bin/env ruby
require "pathname"
require "json"
require "fileutils"
require "erb"

# Load .env file if present (keys not already in ENV)
env_file = File.expand_path("../../.env", __dir__)
if File.exist?(env_file)
  File.foreach(env_file) do |line|
    line.strip!
    next if line.empty? || line.start_with?("#")
    key, value = line.split("=", 2)
    ENV[key] ||= value if key && value && !value.empty?
  end
end

# Load all lib modules
Dir[File.expand_path("lib/**/*.rb", __dir__)].sort.each { |f| require f }

ROOT = Pathname(File.expand_path("../..", __dir__))
DIST = ROOT.join("dist")

def main
  puts "Loading source catalog..."
  catalog = Static::SourceCatalog.new(root: ROOT.join("data/source"))
  catalog.validate!

  read_models = Static::ReadModels.new(catalog)
  renderer = Static::PageRenderer.new(template_root: ROOT.join("scripts/static/templates"))
  media_manifest = Static::MediaManifest.build(topos: catalog.topos, areas: catalog.areas)
  search_builder = Static::SearchIndexBuilder.new(catalog)
  map_builder = Static::MapPayloadBuilder.new(catalog)

  # Build areas_by_id lookup for circuit navigation links
  areas_by_id = catalog.areas.each_with_object({}) { |a, h| h[a["id"]] = a }
  mapbox_token = ENV.fetch("MAPBOX_ACCESS_TOKEN")

  # Clean dist
  FileUtils.rm_rf(DIST)
  FileUtils.mkdir_p(DIST)

  # --- Pages ---

  # Projects page (also the homepage)
  projects_html = renderer.render("projects", "page_title" => "Projects")
  write_page("en/projects/index.html", projects_html)
  write_page("en/index.html", projects_html)

  # Area index
  write_page("en/fontainebleau/index.html", renderer.render("index",
    "page_title" => "Fontainebleau Bouldering",
    "areas" => read_models.all_areas
  ))

  # Area pages
  published_areas = catalog.areas.select { |a| a["published"] }
  puts "Rendering #{published_areas.size} area pages..."
  published_areas.each do |area|
    payload = read_models.area_page(area["slug"])
    next unless payload

    # Pick a topo photo for the area header
    cover_topo_id = read_models.area_cover_topo_id(area["id"])
    cover_image_url = cover_topo_id ? media_manifest.topo_url(cover_topo_id) : nil

    write_page("en/fontainebleau/#{area["slug"]}/index.html", renderer.render("areas/show",
      "page_title" => area["name"],
      "area" => payload["area"],
      "popular_problems" => payload["popular_problems"],
      "circuits" => payload["circuits"],
      "poi_routes" => payload["poi_routes"],
      "media_manifest" => media_manifest,
      "cover_image_url" => cover_image_url
    ))
  end

  # Problem pages
  all_problems = catalog.problems
  puts "Rendering #{all_problems.size} problem pages..."
  all_problems.each_with_index do |problem, i|
    puts "  #{i + 1}/#{all_problems.size} problems..." if (i + 1) % 500 == 0

    payload = read_models.problem_page(problem["id"])
    next unless payload

    area = payload["area"]
    next unless area

    # Pre-render topo HTML
    topo_html = ""
    if payload["line"] && payload["topo"]
      topo_url = begin
        media_manifest.topo_url(payload["topo"]["id"])
      rescue KeyError
        nil
      end

      if topo_url
        topo_html = Static::LineRenderer.render_topo_with_line(
          topo_url: topo_url,
          line: payload["line"],
          circuit_color: problem["circuit_color"],
          circuit_number: problem["circuit_number"]
        )
      end
    end

    problem_slug = [problem["id"], problem["name"]&.downcase&.gsub(/[^a-z0-9]+/, "-")&.gsub(/-$/, "")].compact.join("-")

    write_page("en/fontainebleau/#{area["slug"]}/#{problem_slug}/index.html", renderer.render("problems/show",
      "page_title" => "#{problem["name"]} #{problem["grade"]}",
      "problem" => problem,
      "area" => area,
      "topo_html" => topo_html,
      "circuit" => payload["circuit"],
      "circuit_previous" => payload["circuit_previous"],
      "circuit_next" => payload["circuit_next"],
      "variants" => payload["variants"],
      "area_circuits" => payload["area_circuits"],
      "_areas_by_id" => areas_by_id
    ))
  end

  # Circuit index
  circuits_sorted = catalog.circuits.sort_by { |c| Static::ReadModels::GRADE_VALUES.index(c["average_grade"]) || 0 }
  write_page("en/fontainebleau/circuits/index.html", renderer.render("circuits/index",
    "page_title" => "Circuits",
    "circuits" => circuits_sorted
  ))

  # Circuit detail pages
  puts "Rendering #{catalog.circuits.size} circuit pages..."
  catalog.circuits.each do |circuit|
    problems = read_models.problems_for_circuit(circuit["id"])
    main_area = areas_by_id[circuit["main_area_id"]]
    next unless main_area

    # Add _area_slug to each problem for cross-area linking
    problems.each do |p|
      p_area = areas_by_id[p["area_id"]]
      p["_area_slug"] = p_area ? p_area["slug"] : main_area["slug"]
    end

    write_page("en/fontainebleau/circuits/#{circuit["id"]}/index.html", renderer.render("circuits/show",
      "page_title" => "Circuit #{circuit["color"].capitalize}",
      "circuit" => circuit,
      "problems" => problems,
      "area" => main_area
    ))
  end

  # Boulders page — embed all problems as JSON for client-side filtering (including circuit browsing)
  boulders_problems = catalog.problems.map do |p|
    p_area = areas_by_id[p["area_id"]]
    slug = [p["id"], p["name"]&.downcase&.gsub(/[^a-z0-9]+/, "-")&.gsub(/-$/, "")].compact.join("-")
    loc = p["location"] || {}
    {
      "id" => p["id"],
      "name" => p["name"],
      "grade" => p["grade"],
      "steepness" => p["steepness"],
      "popularity" => p["popularity"] || 0,
      "circuit_id" => p["circuit_id"],
      "circuit_color" => p["circuit_color"],
      "circuit_number" => p["circuit_number"],
      "area_slug" => p_area ? p_area["slug"] : "",
      "area_name" => p_area ? p_area["name"] : "",
      "lat" => loc["lat"],
      "lng" => loc["lng"],
      "url" => "/en/fontainebleau/#{p_area ? p_area["slug"] : ""}/#{slug}"
    }
  end

  # Circuits for the filter dropdown, sorted by area name then color
  boulders_circuits = catalog.circuits
    .select { |c| c["main_area_name"] }
    .sort_by { |c| [c["main_area_name"].downcase, c["color"]] }
    .map { |c| { "id" => c["id"], "color" => c["color"], "area_name" => c["main_area_name"] } }

  write_page("en/fontainebleau/boulders/index.html", renderer.render("boulders",
    "page_title" => "Boulders",
    "problems_json" => JSON.generate(boulders_problems),
    "circuits_json" => JSON.generate(boulders_circuits)
  ))

  # Map pages
  puts "Rendering map pages..."
  map_data = map_builder.build
  map_data_json = JSON.generate(map_data)

  circuits_json = JSON.generate(boulders_circuits)

  # Main map page
  write_page("en/map/index.html", renderer.render_standalone("map",
    "page_title" => "Map",
    "map_data_json" => map_data_json,
    "circuits_json" => circuits_json,
    "bounds_json" => "null",
    "problem_json" => "null",
    "mapbox_token" => mapbox_token
  ))

  # Map pages per area (deep link with bounds)
  published_areas.each do |area|
    bounds = {
      "southWest" => { "lat" => area["south_west_lat"], "lng" => area["south_west_lng"] },
      "northEast" => { "lat" => area["north_east_lat"], "lng" => area["north_east_lng"] }
    }
    write_page("en/map/#{area["slug"]}/index.html", renderer.render_standalone("map",
      "page_title" => "Map — #{area["name"]}",
      "map_data_json" => map_data_json,
      "circuits_json" => circuits_json,
      "bounds_json" => JSON.generate(bounds),
      "problem_json" => "null",
      "mapbox_token" => mapbox_token
    ))
  end

  # --- JSON assets ---

  puts "Writing search index..."
  write_json("assets/search-index.json", search_builder.build)

  puts "Writing map data..."
  write_json("assets/map-data.json", map_builder.build)

  # --- Static assets ---

  puts "Copying static assets..."

  # Stylesheet
  copy_if_exists(ROOT.join("scripts/static/assets/styles.css"), DIST.join("assets/styles.css"))

  # Images
  copy_dir_if_exists(ROOT.join("app/assets/images"), DIST.join("images"))

  # Icons
  copy_if_exists(ROOT.join("public/icon.png"), DIST.join("icon.png"))
  copy_if_exists(ROOT.join("public/icon.svg"), DIST.join("icon.svg"))

  # Topo photos served from CDN (assets.boolder.com) — no local media copy needed

  puts "Done! Output in dist/"
end

def write_page(relative_path, html)
  path = DIST.join(relative_path)
  FileUtils.mkdir_p(path.dirname)
  File.write(path, html)
end

def write_json(relative_path, data)
  path = DIST.join(relative_path)
  FileUtils.mkdir_p(path.dirname)
  File.write(path, JSON.generate(data))
end

def copy_if_exists(src, dest)
  return unless src.exist?
  FileUtils.mkdir_p(dest.dirname)
  FileUtils.cp(src, dest)
end

def copy_dir_if_exists(src, dest)
  return unless src.exist?
  FileUtils.mkdir_p(dest.dirname)
  FileUtils.cp_r(src, dest)
end

main
