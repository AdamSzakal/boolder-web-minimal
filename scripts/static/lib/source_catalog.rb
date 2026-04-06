require "json"
require "pathname"

module Static
  class SourceCatalog
    REQUIRED_FILES = %w[areas.json problems.json circuits.json topos.json lines.json pois.json poi_routes.json].freeze

    def initialize(root: Pathname("data/source"))
      @root = root
    end

    def areas
      @areas ||= read_json("content/areas.json")
    end

    def problems
      @problems ||= read_json("content/problems.json")
    end

    def circuits
      @circuits ||= read_json("content/circuits.json")
    end

    def clusters
      @clusters ||= read_json("content/clusters.json")
    end

    def pois
      @pois ||= read_json("content/pois.json")
    end

    def poi_routes
      @poi_routes ||= read_json("content/poi_routes.json")
    end

    def topos
      @topos ||= read_json("content/topos.json")
    end

    def lines
      @lines ||= read_json("content/lines.json")
    end

    def geojson(name)
      JSON.parse(@root.join("geojson", "#{name}.geojson").read)
    end

    def validate!
      REQUIRED_FILES.each do |f|
        path = @root.join("content", f)
        raise "Missing required source file: #{path}" unless path.exist?
      end

      areas.each do |area|
        raise "Area #{area['id']} missing slug" if area["slug"].to_s.empty?
      end

      problems.each do |problem|
        raise "Problem #{problem['id']} missing area_id" if problem["area_id"].nil?
      end

      topos.select { |t| t["published"] }.each do |topo|
        # photo_path is only required if media has been exported
      end

      true
    end

    private

    def read_json(relative_path)
      JSON.parse(@root.join(relative_path).read)
    end
  end
end
