#!/usr/bin/env ruby
# frozen_string_literal: true

# Static site builder for Boolder.
# Reads source data from data/source/, builds denormalized payloads,
# renders HTML pages, and writes everything to dist/.

require "json"
require "pathname"
require "fileutils"

# Load static build modules
Dir[File.join(__dir__, "lib", "*.rb")].each { |f| require f }

ROOT = Pathname(__dir__).join("../..").expand_path
DIST = ROOT.join("dist")

def main
  puts "Building static site..."

  catalog = Static::SourceCatalog.new(root: ROOT.join("data/source"))
  catalog.validate!

  read_models = Static::ReadModels.new(catalog)
  renderer = Static::PageRenderer.new(template_root: ROOT.join("scripts/static/templates"))
  search_builder = Static::SearchIndexBuilder.new(catalog)
  media_manifest = Static::MediaManifest.build(topos: catalog.topos, areas: catalog.areas)
  map_builder = Static::MapPayloadBuilder.new(catalog)

  # Clean dist
  FileUtils.rm_rf(DIST)
  FileUtils.mkdir_p(DIST)

  %w[en fr].each do |locale|
    puts "  Rendering #{locale} pages..."

    # Homepage
    areas = read_models.all_areas
    write_page(renderer, "index", { "areas" => areas, "locale" => locale }, "#{locale}/index.html")

    # Also write as fontainebleau index
    write_page(renderer, "index", { "areas" => areas, "locale" => locale }, "#{locale}/fontainebleau/index.html")

    # Projects page
    write_page(renderer, "projects", { "locale" => locale }, "#{locale}/projects/index.html")

    # Area pages
    catalog.areas.select { |a| a["published"] == true }.each do |area|
      payload = read_models.area_page(area["slug"])
      write_page(renderer, "areas/show", payload.merge("locale" => locale), "#{locale}/fontainebleau/#{area['slug']}/index.html")
    end

    # Problem pages
    published_problems = catalog.problems.select { |p| p["location"] }
    total = published_problems.length
    published_problems.each_with_index do |problem, i|
      print "    problems: #{i + 1}/#{total}\r" if (i + 1) % 500 == 0 || i + 1 == total
      payload = read_models.problem_page(problem["id"])
      # Pre-render topo with SVG line overlay
      topo_html = ""
      if payload["topo"]
        topo_id = payload["topo"]["id"]
        topo_url = media_manifest.topo_url(topo_id) rescue nil
        if topo_url && payload["line"]
          topo_html = Static::LineRenderer.render_topo_with_line(
            topo_url: topo_url,
            line: payload["line"],
            circuit_color: problem["circuit_color"],
            circuit_number: problem["circuit_number"]
          )
        elsif topo_url
          topo_html = Static::LineRenderer.render_image_only(topo_url)
        end
      end
      area_slug = payload["area"]["slug"]
      write_page(renderer, "problems/show", payload.merge("locale" => locale, "topo_html" => topo_html), "#{locale}/fontainebleau/#{area_slug}/#{problem['id']}/index.html")
    end
    puts

    # Circuit pages — enrich circuits with main_area_name
    areas_by_id = catalog.areas.each_with_object({}) { |a, h| h[a["id"]] = a }
    enriched_circuits = catalog.circuits.map do |c|
      # Find the first problem's area as the "main area"
      first_problem = catalog.problems.find { |p| p["circuit_id"] == c["id"] }
      main_area = first_problem && areas_by_id[first_problem["area_id"]]
      c.merge("main_area_name" => main_area&.fetch("name", nil))
    end

    write_page(renderer, "circuits/index", { "circuits" => enriched_circuits, "locale" => locale }, "#{locale}/fontainebleau/circuits/index.html")

    enriched_circuits.each do |circuit|
      circuit_problems = catalog.problems
        .select { |p| p["circuit_id"] == circuit["id"] && (p["circuit_letter"].nil? || p["circuit_letter"].empty?) }
        .sort_by { |p| p["circuit_number"].to_i }
        .map { |p| p.merge("_area_slug" => areas_by_id[p["area_id"]]&.fetch("slug", "")) }
      main_area = areas_by_id[circuit_problems.first&.fetch("area_id", nil)]
      write_page(renderer, "circuits/show", { "circuit" => circuit, "problems" => circuit_problems, "area" => main_area, "locale" => locale }, "#{locale}/fontainebleau/circuits/#{circuit['id']}/index.html")
    end

    # Boulders page — all popular problems (significant ascents)
    popular = catalog.problems
      .select { |p| p["location"] && p["popularity"].to_i >= 20 }
      .sort_by { |p| -(p["popularity"] || 0) }
      .map { |p| p.merge("_area_slug" => areas_by_id[p["area_id"]]&.fetch("slug", ""), "_area_name" => areas_by_id[p["area_id"]]&.fetch("name", "")) }
    write_page(renderer, "boulders", { "problems" => popular, "locale" => locale }, "#{locale}/fontainebleau/boulders/index.html")
  end

  # Search index
  puts "  Writing search index..."
  write_json("assets/search-index.json", search_builder.build)

  # Map payload
  puts "  Writing map payload..."
  write_json("assets/map-data.json", map_builder.build)

  # Copy media
  puts "  Copying media..."
  media_source = ROOT.join("data/source/media")
  media_dest = DIST.join("media")
  FileUtils.cp_r(media_source, media_dest) if media_source.exist?

  # Copy static assets
  puts "  Copying static assets..."
  assets_dest = DIST.join("assets")
  FileUtils.mkdir_p(assets_dest)

  # Tailwind CSS
  tailwind_src = ROOT.join("app/assets/builds/tailwind.css")
  FileUtils.cp(tailwind_src, assets_dest.join("tailwind.css")) if tailwind_src.exist?

  # Inter font CSS (if exists)
  inter_src = ROOT.join("app/assets/builds/inter-font.css")
  FileUtils.cp(inter_src, assets_dest.join("inter-font.css")) if inter_src.exist?

  # Images
  images_src = ROOT.join("app/assets/images")
  if images_src.exist?
    FileUtils.cp_r(images_src, DIST.join("images"))
  end

  # Public assets (icons, etc)
  %w[icon.png icon.svg].each do |file|
    src = ROOT.join("public", file)
    FileUtils.cp(src, DIST.join(file)) if src.exist?
  end

  puts "Done! Output in dist/"
end

def write_page(renderer, template, locals, relative_path)
  html = renderer.render(template, locals)
  output = DIST.join(relative_path)
  FileUtils.mkdir_p(output.dirname)
  output.write(html)
end

def write_json(relative_path, data)
  output = DIST.join(relative_path)
  FileUtils.mkdir_p(output.dirname)
  output.write(JSON.pretty_generate(data))
end

main
