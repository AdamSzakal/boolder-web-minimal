module Static
  class SearchIndexBuilder
    def initialize(catalog)
      @catalog = catalog
      @areas_by_id = catalog.areas.each_with_object({}) { |a, h| h[a["id"]] = a }
    end

    def build
      {
        "areas" => @catalog.areas.select { |a| a["published"] }.map { |a|
          {
            "name" => a["name"],
            "n" => normalize(a["name"]),
            "url" => "/en/fontainebleau/#{a["slug"]}"
          }
        },
        "problems" => @catalog.problems.map { |p|
          area = @areas_by_id[p["area_id"]]
          slug = [p["id"], p["name"]&.downcase&.gsub(/[^a-z0-9]+/, "-")&.gsub(/-$/, "")].compact.join("-")
          loc = p["location"] || {}
          {
            "id" => p["id"],
            "name" => p["name"],
            "n" => normalize(p["name"]),
            "grade" => p["grade"],
            "pop" => p["popularity"] || 0,
            "area" => area ? area["name"] : "",
            "st" => p["steepness"],
            "cc" => p["circuit_color"],
            "cn" => p["circuit_number"],
            "cid" => p["circuit_id"],
            "lat" => loc["lat"],
            "lng" => loc["lng"],
            "url" => "/en/fontainebleau/#{area ? area["slug"] : ""}/#{slug}"
          }
        }
      }
    end

    private

    # Unicode NFKD decompose, strip combining marks, strip non-alphanumeric, downcase
    def normalize(str)
      return "" if str.nil?
      str.unicode_normalize(:nfkd)
         .gsub(/[\u0300-\u036f]/, "")
         .gsub(/[^a-zA-Z0-9]/, "")
         .downcase
    end
  end
end
