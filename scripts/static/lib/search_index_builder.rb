module Static
  class SearchIndexBuilder
    def initialize(catalog)
      @catalog = catalog
    end

    def build
      {
        "areas" => build_area_entries,
        "problems" => build_problem_entries
      }
    end

    private

    def build_area_entries
      @catalog.areas
        .select { |a| a["published"] == true }
        .map do |area|
          {
            "id" => area.fetch("id"),
            "slug" => area.fetch("slug"),
            "name" => area.fetch("name"),
            "normalized_name" => normalize(area.fetch("name"))
          }
        end
    end

    def build_problem_entries
      @catalog.problems
        .select { |p| p["location"] }
        .map do |problem|
          {
            "id" => problem.fetch("id"),
            "area_id" => problem.fetch("area_id"),
            "name" => problem["name"],
            "normalized_name" => normalize(problem["name"]),
            "grade" => problem["grade"],
            "popularity" => problem["popularity"]
          }
        end
    end

    # Strips accents/diacritics and non-alphanumeric characters, lowercases
    def normalize(string)
      return "" if string.nil?

      # Decompose unicode, strip combining marks, lowercase
      string
        .unicode_normalize(:nfkd)
        .gsub(/[\u0300-\u036f]/, "")
        .gsub(/[^0-9a-zA-Z]/, "")
        .downcase
    end
  end
end
