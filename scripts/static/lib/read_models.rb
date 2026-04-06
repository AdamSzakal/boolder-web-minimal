module Static
  class ReadModels
    # Self-contained grade ordering (don't reference Problem::GRADE_VALUES)
    GRADE_VALUES = %w[
      1a 1a+ 1b 1b+ 1c 1c+
      2a 2a+ 2b 2b+ 2c 2c+
      3a 3a+ 3b 3b+ 3c 3c+
      4a 4a+ 4b 4b+ 4c 4c+
      5a 5a+ 5b 5b+ 5c 5c+
      6a 6a+ 6b 6b+ 6c 6c+
      7a 7a+ 7b 7b+ 7c 7c+
      8a 8a+ 8b 8b+ 8c 8c+
      9a 9a+ 9b 9b+ 9c 9c+
    ].freeze

    attr_reader :catalog

    def initialize(catalog)
      @catalog = catalog
      build_indexes!
    end

    # --- Page payloads ---

    def area_page(slug)
      area = @areas_by_slug[slug]
      return nil unless area

      area_id = area["id"]
      problems = @problems_by_area[area_id] || []

      {
        "area" => area,
        "popular_problems" => popular_problems_for(area_id),
        "circuits" => circuits_for(area_id),
        "poi_routes" => poi_routes_for(area_id)
      }
    end

    def problem_page(problem_id)
      problem = @problems_by_id[problem_id]
      return nil unless problem

      area = @areas_by_id[problem["area_id"]]
      line = @lines_by_problem_id[problem_id]
      topo = line ? @topos_by_id[line["topo_id"]] : nil

      variants = build_variants(problem)

      circuit = nil
      circuit_previous = nil
      circuit_next = nil

      if problem["circuit_id"] && problem["circuit_number"]
        circuit = @circuits_by_id[problem["circuit_id"]]
        num = problem["circuit_number"].to_i

        # Previous: num-1, or "D" (start) if num==1
        if num == 1
          circuit_previous = @circuit_problems[[problem["circuit_id"], "D"]]
        elsif num > 1
          circuit_previous = @circuit_problems[[problem["circuit_id"], (num - 1).to_s]]
        end

        # Next: num+1
        circuit_next = @circuit_problems[[problem["circuit_id"], (num + 1).to_s]]
      end

      {
        "problem" => problem,
        "area" => area,
        "line" => line,
        "topo" => topo,
        "variants" => variants,
        "circuit" => circuit,
        "circuit_previous" => circuit_previous,
        "circuit_next" => circuit_next
      }
    end

    def all_areas
      catalog.areas
        .select { |a| a["published"] }
        .sort_by { |a| a["name"].downcase }
    end

    def all_problems
      catalog.problems
    end

    def problems_for_circuit(circuit_id)
      (@problems_by_circuit[circuit_id] || [])
        .sort_by { |p| enumerable_circuit_number(p) }
    end

    def area_by_id(id)
      @areas_by_id[id]
    end

    def area_by_slug(slug)
      @areas_by_slug[slug]
    end

    private

    def build_indexes!
      @areas_by_id = catalog.areas.each_with_object({}) { |a, h| h[a["id"]] = a }
      @areas_by_slug = catalog.areas.each_with_object({}) { |a, h| h[a["slug"]] = a }
      @problems_by_id = catalog.problems.each_with_object({}) { |p, h| h[p["id"]] = p }
      @problems_by_area = catalog.problems.group_by { |p| p["area_id"] }
      @problems_by_parent = catalog.problems.select { |p| p["parent_id"] }.group_by { |p| p["parent_id"] }
      @circuits_by_id = catalog.circuits.each_with_object({}) { |c, h| h[c["id"]] = c }
      @topos_by_id = catalog.topos.each_with_object({}) { |t, h| h[t["id"]] = t }
      @lines_by_problem_id = catalog.lines.each_with_object({}) { |l, h| h[l["problem_id"]] = l }
      @pois_by_id = catalog.pois.each_with_object({}) { |p, h| h[p["id"]] = p }
      @poi_routes_by_area = catalog.poi_routes.group_by { |r| r["area_id"] }

      # Circuit navigation: keyed by [circuit_id, number_string]
      # Only main problems (no circuit_letter / bis)
      @circuit_problems = {}
      catalog.problems.each do |p|
        next unless p["circuit_id"] && p["circuit_number"]
        @circuit_problems[[p["circuit_id"], p["circuit_number"]]] = p
      end

      # Problems grouped by circuit
      @problems_by_circuit = catalog.problems
        .select { |p| p["circuit_id"] }
        .group_by { |p| p["circuit_id"] }
    end

    def popular_problems_for(area_id)
      problems = @problems_by_area[area_id] || []
      problems
        .select { |p| p["featured"] || (p["popularity"] && p["popularity"] >= 20) }
        .sort_by { |p| [-(grade_value(p["grade"])), -(p["popularity"] || 0)] }
    end

    def circuits_for(area_id)
      circuit_ids = (@problems_by_area[area_id] || []).map { |p| p["circuit_id"] }.compact.uniq
      circuit_ids.map { |id| @circuits_by_id[id] }.compact.sort_by { |c| grade_value(c["average_grade"]) }
    end

    def poi_routes_for(area_id)
      routes = @poi_routes_by_area[area_id] || []
      routes.map do |route|
        poi = @pois_by_id[route["poi_id"]]
        route.merge("poi" => poi)
      end
    end

    def build_variants(problem)
      if problem["parent_id"]
        parent = @problems_by_id[problem["parent_id"]]
        siblings = @problems_by_parent[problem["parent_id"]] || []
        ([parent] + siblings).compact.reject { |p| p["id"] == problem["id"] }
      else
        (@problems_by_parent[problem["id"]] || [])
      end.sort_by { |p| -(grade_value(p["grade"])) }
    end

    def grade_value(grade)
      GRADE_VALUES.index(grade) || -1
    end

    def enumerable_circuit_number(problem)
      num = problem["circuit_number"].to_i.to_f
      # circuit_color-based bis detection not available, just sort by number
      num
    end
  end
end
