namespace :static do
  desc "Export all DB tables to data/source/content/*.json for static site build"
  task export: :environment do
    output_dir = Rails.root.join("data", "source", "content")
    FileUtils.mkdir_p(output_dir)

    export_areas(output_dir)
    export_problems(output_dir)
    export_circuits(output_dir)
    export_clusters(output_dir)
    export_pois(output_dir)
    export_poi_routes(output_dir)
    export_topos(output_dir)
    export_lines(output_dir)

    puts "Done! All source JSON written to #{output_dir}".green
  end

  desc "Export topo photos and area covers to data/source/media/"
  task export_media: :environment do
    ensure_s3_service!

    media_dir = Rails.root.join("data", "source", "media")

    export_topo_photos(media_dir)
    export_area_covers(media_dir)

    puts "Done! Media exported to #{media_dir}".green
  end
end

def export_areas(dir)
  records = Area.published.order(:id).map do |a|
    bounds = a.serialized_bounds
    level_counts = 1.upto(8).map { |n| ["level#{n}_count", a.problems.with_location.level(n).count] }.to_h

    {
      "id" => a.id,
      "slug" => a.slug,
      "name" => a.name,
      "short_name" => a.short_name,
      "priority" => a.priority,
      "tags" => a.tags,
      "description_fr" => a.description_fr.presence,
      "description_en" => a.description_en.presence,
      "warning_fr" => a.warning_fr.presence,
      "warning_en" => a.warning_en.presence,
      "published" => a.published,
      "cluster_id" => a.cluster_id,
      "south_west_lat" => bounds[:south_west][:lat],
      "south_west_lng" => bounds[:south_west][:lng],
      "north_east_lat" => bounds[:north_east][:lat],
      "north_east_lng" => bounds[:north_east][:lng],
      "problems_count" => a.problems.with_location.count,
      "name_searchable" => normalize(a.name)
    }.merge(level_counts)
  end

  write_json(dir, "areas.json", records)
end

def export_problems(dir)
  records = Problem.with_location
    .joins(:area).where(areas: { published: true })
    .order(:id)
    .find_each.map do |p|
      {
        "id" => p.id,
        "area_id" => p.area_id,
        "name" => I18n.with_locale(:en) { p.name_with_fallback },
        "name_searchable" => normalize(p.name),
        "grade" => p.grade,
        "steepness" => p.steepness,
        "sit_start" => p.sit_start,
        "location" => { "lat" => p.location.lat, "lng" => p.location.lon },
        "circuit_id" => p.circuit_id_simplified,
        "circuit_number" => p.circuit_number_simplified,
        "circuit_color" => p.circuit&.color,
        "featured" => p.featured,
        "popularity" => p.popularity,
        "bleau_info_id" => p.bleau_info_id.to_s.presence,
        "parent_id" => p.parent_id
      }
    end

  write_json(dir, "problems.json", records)
end

def export_circuits(dir)
  records = Circuit.all.select { |c| c.problems.count > 0 }.sort_by(&:id).map do |c|
    main_area = c.main_area
    bounds = c.bounds

    {
      "id" => c.id,
      "color" => c.color,
      "average_grade" => c.average_grade,
      "beginner_friendly" => c.beginner_friendly?,
      "dangerous" => c.dangerous?,
      "main_area_id" => main_area&.id,
      "main_area_name" => main_area&.name,
      "south_west_lat" => bounds[:south_west]&.lat,
      "south_west_lng" => bounds[:south_west]&.lon,
      "north_east_lat" => bounds[:north_east]&.lat,
      "north_east_lng" => bounds[:north_east]&.lon
    }
  end

  write_json(dir, "circuits.json", records)
end

def export_clusters(dir)
  records = Cluster.order(:id).map do |c|
    {
      "id" => c.id,
      "name" => c.name,
      "main_area_id" => c.main_area_id,
      "center_lat" => c.center&.lat,
      "center_lng" => c.center&.lon,
      "south_west_lat" => c.sw&.lat,
      "south_west_lng" => c.sw&.lon,
      "north_east_lat" => c.ne&.lat,
      "north_east_lng" => c.ne&.lon
    }
  end

  write_json(dir, "clusters.json", records)
end

def export_pois(dir)
  records = Poi.order(:id).map do |p|
    {
      "id" => p.id,
      "poi_type" => p.poi_type,
      "name" => p.name,
      "short_name" => p.short_name,
      "google_url" => p.google_url,
      "location" => { "lat" => p.location&.lat, "lng" => p.location&.lon }
    }
  end

  write_json(dir, "pois.json", records)
end

def export_poi_routes(dir)
  records = PoiRoute.order(:id).map do |pr|
    {
      "id" => pr.id,
      "area_id" => pr.area_id,
      "poi_id" => pr.poi_id,
      "distance" => pr.distance,
      "transport" => pr.transport
    }
  end

  write_json(dir, "poi_routes.json", records)
end

def export_topos(dir)
  records = Topo.published
    .joins(:problems).where(problems: { area_id: Area.published.select(:id) })
    .group("topos.id")
    .order(:id)
    .map do |t|
      {
        "id" => t.id,
        "area_id" => t.area_id,
        "boulder_id" => t.boulder_id,
        "position" => t.position,
        "published" => t.published
      }
    end

  write_json(dir, "topos.json", records)
end

def export_lines(dir)
  records = Line.joins(problem: :area).joins(:topo)
    .where(areas: { published: true }, topos: { published: true })
    .order(:id)
    .map do |l|
      {
        "id" => l.id,
        "problem_id" => l.problem_id,
        "topo_id" => l.topo_id,
        "coordinates" => l.coordinates
      }
    end

  write_json(dir, "lines.json", records)
end

def export_topo_photos(media_dir)
  topos_dir = media_dir.join("topos")

  Topo.published.joins(:problems).where(problems: { area_id: Area.published.select(:id) }).group("topos.id").find_each do |t|
    area_dir = topos_dir.join("area-#{t.area_id}")
    output_file = area_dir.join("topo-#{t.id}.jpg")

    next if File.exist?(output_file)
    next unless t.photo.attached?

    FileUtils.mkdir_p(area_dir)
    t.photo.open do |file|
      im = Vips::Image.new_from_file(file.path.to_s)
      im.thumbnail_image(800).write_to_file(output_file.to_s)
    end
    puts "  topo-#{t.id}.jpg"
  end

  puts "Exported topo photos"
end

def export_area_covers(media_dir)
  covers_dir = media_dir.join("area-covers")
  FileUtils.mkdir_p(covers_dir)

  Area.published.order(:id).each do |a|
    output_file = covers_dir.join("area-cover-#{a.id}.jpg")

    next if File.exist?(output_file)
    next unless a.cover.attached?

    a.cover.open do |file|
      im = Vips::Image.new_from_file(file.path.to_s)
      im.thumbnail_image(400).write_to_file(output_file.to_s)
    end
    puts "  area-cover-#{a.id}.jpg"
  end

  puts "Exported area covers"
end

# Auto-switch to S3 service if blobs are stored there
def ensure_s3_service!
  sample_blob = ActiveStorage::Blob.last
  return unless sample_blob

  if sample_blob.service_name == "amazon"
    ActiveStorage::Blob.service = ActiveStorage::Blob.services.fetch(:amazon)
    puts "Switched to S3 service for media export"
  end
end

def normalize(string)
  return nil if string.nil?
  I18n.with_locale(:fr) { I18n.transliterate(string) }.gsub(/[^0-9a-zA-Z]/, "")&.downcase
end

def write_json(dir, filename, records)
  path = dir.join(filename)
  File.write(path, JSON.pretty_generate(records))
  puts "  #{filename}: #{records.size} records"
end
