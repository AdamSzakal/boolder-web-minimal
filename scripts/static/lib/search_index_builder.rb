require "unicode_normalize"

module Static
  class SearchIndexBuilder
    def initialize(catalog)
      @catalog = catalog
    end

    def build
      {
        "areas" => @catalog.areas.select { |a| a["published"] }.map { |a|
          {
            "id" => a["id"],
            "slug" => a["slug"],
            "name" => a["name"],
            "normalized_name" => normalize(a["name"])
          }
        },
        "problems" => @catalog.problems.map { |p|
          {
            "id" => p["id"],
            "area_id" => p["area_id"],
            "name" => p["name"],
            "normalized_name" => normalize(p["name"]),
            "grade" => p["grade"],
            "popularity" => p["popularity"]
          }
        }
      }
    end

    private

    # Unicode NFKD decompose, strip combining marks, strip non-alphanumeric, downcase
    def normalize(str)
      return "" if str.nil?
      str.unicode_normalize(:nfkd)
         .gsub(/[\u0300-\u036f]/, "") # strip combining marks (accents)
         .gsub(/[^a-zA-Z0-9]/, "")
         .downcase
    end
  end
end
