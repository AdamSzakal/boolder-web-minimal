require "json"

module Static
  class MapPayloadBuilder
    def initialize(catalog)
      @catalog = catalog
    end

    # Builds area bounds keyed by slug for map deep links
    def area_bounds
      @catalog.areas
        .select { |a| a["published"] == true }
        .each_with_object({}) do |area, hash|
          hash[area["slug"]] = area["bounds"]
        end
    end

    # Builds the full map payload for embedding in the map page
    def build
      {
        "areas" => area_bounds,
        "problems" => problem_features
      }
    end

    private

    def problem_features
      @catalog.problems
        .select { |p| p["location"] }
        .map do |p|
          {
            "id" => p["id"],
            "name" => p["name"],
            "grade" => p["grade"],
            "location" => p["location"],
            "circuit_color" => p["circuit_color"],
            "circuit_number" => p["circuit_number"],
            "area_id" => p["area_id"],
            "featured" => p["featured"],
            "popularity" => p["popularity"],
            "steepness" => p["steepness"]
          }
        end
    end
  end
end
