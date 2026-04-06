require "json"
require "fileutils"

namespace :static do
  desc "Export current DB data into data/source/content/ JSON files for the static build"
  task export: :environment do
    output_dir = Rails.root.join("data/source/content")
    FileUtils.mkdir_p(output_dir)

    export_areas(output_dir)
    export_problems(output_dir)
    export_circuits(output_dir)
    export_clusters(output_dir)
    export_pois(output_dir)
    export_poi_routes(output_dir)
    export_topos(output_dir)
    export_lines(output_dir)

    puts "✓ All source files exported to #{output_dir}".green
  end

  desc "Export topo photos and area covers into data/source/media/"
  task export_media: :environment do
    ensure_s3_service!
    export_topo_photos
    export_area_covers
  end
end

# Switch to the S3 service for downloading blobs, since dev defaults to local disk
# but all blobs were uploaded to S3 in production.
def ensure_s3_service!
  blob = ActiveStorage::Blob.first
  return unless blob&.service_name == "amazon"

  if ActiveStorage::Blob.service.is_a?(ActiveStorage::Service::DiskService)
    puts "Blobs are on S3 — switching Active Storage service to :amazon"
    puts "  Requires S3_READONLY_KEY and S3_READONLY_SECRET env vars,"
    puts "  or AWS credentials in Rails credentials."
    ActiveStorage::Blob.service = ActiveStorage::Blob.services.fetch(:amazon)
  end
end

def write_json(dir, filename, data)
  path = File.join(dir, filename)
  File.write(path, JSON.pretty_generate(data))
  puts "  wrote #{filename} (#{data.length} records)"
end

def export_areas(dir)
  data = Area.all.map do |a|
    bounds = begin
      a.serialized_bounds
    rescue
      { south_west: { lat: 0.0, lng: 0.0 }, north_east: { lat: 0.0, lng: 0.0 } }
    end

    levels = 1.upto(8).each_with_object({}) do |level, hash|
      hash[level.to_s] = a.problems.with_location.level(level).count
    rescue
      hash[level.to_s] = 0
    end

    {
      "id" => a.id,
      "slug" => a.slug,
      "name" => a.name,
      "short_name" => a.short_name,
      "priority" => a.priority,
      "tags" => a.tags,
      "description_fr" => a.description_fr,
      "description_en" => a.description_en,
      "warning_fr" => a.warning_fr,
      "warning_en" => a.warning_en,
      "published" => a.published,
      "cluster_id" => a.cluster_id,
      "bounds" => {
        "south_west" => { "lat" => bounds[:south_west][:lat], "lng" => bounds[:south_west][:lng] },
        "north_east" => { "lat" => bounds[:north_east][:lat], "lng" => bounds[:north_east][:lng] }
      },
      "levels" => levels,
      "problems_count" => a.problems.with_location.count
    }
  end

  write_json(dir, "areas.json", data)
end

def export_problems(dir)
  data = Problem.with_location.joins(:area).where(area: { published: true }).map do |p|
    name_fr = I18n.with_locale(:fr) { p.name_with_fallback }
    name_en = I18n.with_locale(:en) { p.name_with_fallback }

    {
      "id" => p.id,
      "area_id" => p.area_id,
      "name" => name_fr,
      "name_en" => (name_en != name_fr) ? name_en : nil,
      "grade" => p.grade,
      "steepness" => p.steepness,
      "sit_start" => p.sit_start,
      "location" => { "lat" => p.location&.lat, "lng" => p.location&.lon },
      "circuit_id" => p.circuit_id_simplified,
      "circuit_number" => p.circuit_number_simplified,
      "circuit_color" => p.circuit&.color,
      "featured" => p.featured,
      "popularity" => p.popularity,
      "bleau_info_id" => p.bleau_info_id&.to_s,
      "parent_id" => p.parent_id
    }
  end

  write_json(dir, "problems.json", data)
end

def export_circuits(dir)
  data = Circuit.all.select { |c| c.problems.count > 0 }.map do |c|
    {
      "id" => c.id,
      "color" => c.color,
      "average_grade" => c.average_grade,
      "beginner_friendly" => c.beginner_friendly?,
      "dangerous" => c.dangerous?,
      "risk" => c.risk
    }
  end

  write_json(dir, "circuits.json", data)
end

def export_clusters(dir)
  data = Cluster.all.map do |c|
    {
      "id" => c.id,
      "name" => c.name,
      "main_area_id" => c.main_area_id
    }
  end

  write_json(dir, "clusters.json", data)
end

def export_pois(dir)
  data = Poi.all.map do |p|
    {
      "id" => p.id,
      "poi_type" => p.poi_type,
      "name" => p.name,
      "short_name" => p.short_name,
      "google_url" => p.google_url,
      "location" => { "lat" => p.location&.lat, "lng" => p.location&.lon }
    }
  end

  write_json(dir, "pois.json", data)
end

def export_poi_routes(dir)
  data = PoiRoute.all.map do |pr|
    {
      "id" => pr.id,
      "area_id" => pr.area_id,
      "poi_id" => pr.poi_id,
      "distance" => pr.distance,
      "transport" => pr.transport
    }
  end

  write_json(dir, "poi_routes.json", data)
end

def export_topos(dir)
  data = Topo.published.joins(:problems).group("topos.id").map do |t|
    {
      "id" => t.id,
      "area_id" => t.area_id,
      "published" => t.published,
      "photo_path" => "topo-#{t.id}.jpg"
    }
  end

  write_json(dir, "topos.json", data)
end

def export_lines(dir)
  data = Line.joins(problem: :area).joins(:topo)
    .where(area: { published: true }, topo: { published: true })
    .map do |l|
    {
      "id" => l.id,
      "problem_id" => l.problem_id,
      "topo_id" => l.topo_id,
      "coordinates" => l.coordinates
    }
  end

  write_json(dir, "lines.json", data)
end

def export_topo_photos
  media_dir = Rails.root.join("data/source/media/topos")

  Area.published.each do |area|
    area_dir = media_dir.join("area-#{area.id}")
    FileUtils.mkdir_p(area_dir)

    Topo.published.joins(lines: :problem).where(problems: { area_id: area.id }).distinct.each do |topo|
      output_file = area_dir.join("topo-#{topo.id}.jpg")
      next if output_file.exist?

      begin
        topo.photo.open do |file|
          FileUtils.cp(file.path, output_file)
        end
        puts "  exported topo-#{topo.id}.jpg"
      rescue => e
        puts "  ⚠ skipped topo #{topo.id}: #{e.message}"
      end
    end
  end

  puts "✓ Topo photos exported"
end

def export_area_covers
  media_dir = Rails.root.join("data/source/media/area-covers")
  FileUtils.mkdir_p(media_dir)

  Area.published.each do |area|
    output_file = media_dir.join("area-cover-#{area.id}.jpg")
    next if output_file.exist?

    begin
      area.cover.open do |file|
        FileUtils.cp(file.path, output_file)
      end
      puts "  exported area-cover-#{area.id}.jpg"
    rescue => e
      puts "  ⚠ skipped area cover #{area.id}: #{e.message}"
    end
  end

  puts "✓ Area covers exported"
end
