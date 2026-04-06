module Static
  class MapPayloadBuilder
    def initialize(catalog)
      @catalog = catalog
    end

    def build
      {
        "areas" => build_area_bounds,
        "problems" => build_problem_features
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

    def build_problem_features
      @catalog.problems.map do |p|
        {
          "id" => p["id"],
          "area_id" => p["area_id"],
          "name" => p["name"],
          "grade" => p["grade"],
          "steepness" => p["steepness"],
          "location" => p["location"],
          "circuit_color" => p["circuit_color"],
          "circuit_number" => p["circuit_number"],
          "featured" => p["featured"],
          "popularity" => p["popularity"]
        }
      end
    end
  end
end
