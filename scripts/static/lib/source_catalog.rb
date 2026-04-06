require "json"
require "pathname"

module Static
  class SourceCatalog
    CONTENT_FILES = %w[areas problems circuits clusters pois poi_routes topos lines].freeze

    def initialize(root: Pathname("data/source"))
      @root = Pathname(root)
    end

    def areas
      read_json("content/areas.json")
    end

    def problems
      read_json("content/problems.json")
    end

    def circuits
      read_json("content/circuits.json")
    end

    def clusters
      read_json("content/clusters.json")
    end

    def pois
      read_json("content/pois.json")
    end

    def poi_routes
      read_json("content/poi_routes.json")
    end

    def topos
      read_json("content/topos.json")
    end

    def lines
      read_json("content/lines.json")
    end

    def geojson(name)
      path = @root.join("geojson", "#{name}.geojson")
      JSON.parse(path.read)
    end

    # Validates that the source bundle is complete enough to build from.
    # Raises on the first validation error found.
    def validate!
      validate_required_files!
      validate_areas!
      validate_problems!
      validate_topos!
    end

    private

    def read_json(relative_path)
      path = @root.join(relative_path)
      raise "Missing source file: #{path}" unless path.exist?

      JSON.parse(path.read)
    end

    def validate_required_files!
      CONTENT_FILES.each do |name|
        path = @root.join("content", "#{name}.json")
        raise "Missing required source file: #{path}" unless path.exist?
      end
    end

    def validate_areas!
      areas.each do |area|
        raise "Area #{area['id']}: missing slug" if area["slug"].to_s.empty?
        raise "Area #{area['id']}: missing name" if area["name"].to_s.empty?
      end
    end

    def validate_problems!
      problems.each do |problem|
        raise "Problem #{problem['id']}: missing area_id" if problem["area_id"].nil?
        if problem["location"] && problem["location"]["lat"].nil?
          raise "Problem #{problem['id']}: location present but lat is nil"
        end
      end
    end

    def validate_topos!
      topos.each do |topo|
        if topo["published"] && topo["photo_path"].to_s.empty?
          raise "Topo #{topo['id']}: published but missing photo_path"
        end
      end
    end
  end
end
