module Static
  class MapPayloadBuilder
    def initialize(catalog)
      @catalog = catalog
      @areas_by_id = catalog.areas.each_with_object({}) { |a, h| h[a["id"]] = a }
    end

    def build
      {
        "areas" => build_area_bounds,
        "problemLookup" => build_problem_lookup
      }
    end

    private

    def build_area_bounds
      result = {}
      @catalog.areas.select { |a| a["published"] }.each do |a|
        result[a["slug"]] = {
          "southWest" => { "lat" => a["south_west_lat"], "lng" => a["south_west_lng"] },
          "northEast" => { "lat" => a["north_east_lat"], "lng" => a["north_east_lng"] }
        }
      end
      result
    end

    # Lookup keyed by problem ID for map popup links
    def build_problem_lookup
      result = {}
      @catalog.problems.each do |p|
        area = @areas_by_id[p["area_id"]]
        next unless area

        slug = [p["id"], p["name"]&.downcase&.gsub(/[^a-z0-9]+/, "-")&.gsub(/-$/, "")].compact.join("-")
        result[p["id"].to_s] = {
          "url" => "/en/fontainebleau/#{area["slug"]}/#{slug}",
          "name" => p["name"],
          "grade" => p["grade"]
        }
      end
      result
    end
  end
end
