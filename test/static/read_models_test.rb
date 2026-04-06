require "test_helper"
require_relative "../../scripts/static/lib/source_catalog"
require_relative "../../scripts/static/lib/read_models"

class Static::ReadModelsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  fixtures []

  setup do
    @catalog = Static::FakeCatalog.new
    @read_models = Static::ReadModels.new(@catalog)
  end

  test "area_page payload includes area, popular problems, circuits, and poi routes" do
    payload = @read_models.area_page("franchard-isatis")

    assert_equal "Franchard Isatis", payload.fetch("area").fetch("name")
    assert_equal "franchard-isatis", payload.fetch("area").fetch("slug")
    assert payload.fetch("popular_problems").any?
    assert payload.fetch("popular_problems").all? { |p| p["featured"] == true }
    assert payload.fetch("circuits").any?
    assert payload.fetch("poi_routes").any?
    assert payload.fetch("poi_routes").all? { |route| route.key?("transport") }
  end

  test "area_page popular problems are sorted by grade desc then popularity desc" do
    payload = @read_models.area_page("franchard-isatis")
    problems = payload.fetch("popular_problems")

    # Higher grade first, then higher popularity within same grade
    grades = problems.map { |p| p["grade"] }
    assert_equal grades, grades.sort.reverse
  end

  test "problem_page payload includes problem, area, line, topo, and variants" do
    payload = @read_models.problem_page(10)

    assert_equal "Carnage", payload.fetch("problem").fetch("name")
    assert_equal "7b", payload.fetch("problem").fetch("grade")
    assert_equal "Franchard Isatis", payload.fetch("area").fetch("name")
    assert payload.key?("line")
    assert payload.key?("topo")
    assert payload.key?("variants")
  end

  test "problem_page includes circuit navigation" do
    payload = @read_models.problem_page(10)

    assert payload.key?("circuit")
    assert payload.key?("circuit_previous")
    assert payload.key?("circuit_next")
  end

  test "all_areas returns published areas sorted by name" do
    areas = @read_models.all_areas

    assert areas.all? { |a| a["published"] == true }
    names = areas.map { |a| a["name"] }
    assert_equal names, names.sort
  end
end

module Static
  class FakeCatalog
    def areas
      [
        {
          "id" => 1, "slug" => "franchard-isatis", "name" => "Franchard Isatis",
          "short_name" => "Isatis", "priority" => 10,
          "tags" => ["popular", "beginner_friendly"],
          "description_fr" => "Un secteur magnifique", "description_en" => "A beautiful area",
          "warning_fr" => nil, "warning_en" => nil,
          "published" => true, "cluster_id" => 1,
          "bounds" => { "south_west" => { "lat" => 48.4, "lng" => 2.6 }, "north_east" => { "lat" => 48.41, "lng" => 2.61 } },
          "levels" => { "1" => 5, "2" => 10, "3" => 15, "4" => 20, "5" => 25, "6" => 18, "7" => 8, "8" => 2 },
          "problems_count" => 103
        },
        {
          "id" => 2, "slug" => "cuvier", "name" => "Cuvier",
          "short_name" => nil, "priority" => 8,
          "tags" => ["popular"],
          "description_fr" => nil, "description_en" => nil,
          "warning_fr" => nil, "warning_en" => nil,
          "published" => true, "cluster_id" => 1,
          "bounds" => { "south_west" => { "lat" => 48.44, "lng" => 2.63 }, "north_east" => { "lat" => 48.45, "lng" => 2.64 } },
          "levels" => { "1" => 3, "2" => 7, "3" => 12, "4" => 18, "5" => 22, "6" => 15, "7" => 6, "8" => 1 },
          "problems_count" => 84
        },
        {
          "id" => 3, "slug" => "unpublished-area", "name" => "Unpublished",
          "short_name" => nil, "priority" => 1,
          "tags" => [],
          "description_fr" => nil, "description_en" => nil,
          "warning_fr" => nil, "warning_en" => nil,
          "published" => false, "cluster_id" => 1,
          "bounds" => { "south_west" => { "lat" => 48.5, "lng" => 2.7 }, "north_east" => { "lat" => 48.51, "lng" => 2.71 } },
          "levels" => {},
          "problems_count" => 0
        }
      ]
    end

    def problems
      [
        {
          "id" => 10, "area_id" => 1, "name" => "Carnage", "grade" => "7b",
          "steepness" => "overhang", "sit_start" => false,
          "location" => { "lat" => 48.405, "lng" => 2.605 },
          "circuit_id" => 1, "circuit_number" => "24", "circuit_color" => "red",
          "featured" => true, "popularity" => 95, "bleau_info_id" => "123", "parent_id" => nil
        },
        {
          "id" => 11, "area_id" => 1, "name" => "La Marie-Rose", "grade" => "6a",
          "steepness" => "wall", "sit_start" => false,
          "location" => { "lat" => 48.406, "lng" => 2.606 },
          "circuit_id" => 1, "circuit_number" => "23", "circuit_color" => "red",
          "featured" => true, "popularity" => 80, "bleau_info_id" => nil, "parent_id" => nil
        },
        {
          "id" => 12, "area_id" => 1, "name" => "Carnage (assis)", "grade" => "7c",
          "steepness" => "overhang", "sit_start" => true,
          "location" => { "lat" => 48.405, "lng" => 2.605 },
          "circuit_id" => nil, "circuit_number" => nil, "circuit_color" => nil,
          "featured" => false, "popularity" => 60, "bleau_info_id" => nil, "parent_id" => 10
        },
        {
          "id" => 13, "area_id" => 1, "name" => "Next Problem", "grade" => "6b",
          "steepness" => "slab", "sit_start" => false,
          "location" => { "lat" => 48.407, "lng" => 2.607 },
          "circuit_id" => 1, "circuit_number" => "25", "circuit_color" => "red",
          "featured" => false, "popularity" => 50, "bleau_info_id" => nil, "parent_id" => nil
        }
      ]
    end

    def circuits
      [
        { "id" => 1, "color" => "red", "average_grade" => "6a", "beginner_friendly" => false, "dangerous" => false, "risk" => 2 }
      ]
    end

    def clusters
      [
        { "id" => 1, "name" => "Franchard", "main_area_id" => 1 }
      ]
    end

    def pois
      [
        { "id" => 1, "poi_type" => "parking", "name" => "Parking Isatis", "short_name" => "P. Isatis", "google_url" => "https://maps.google.com/123", "location" => { "lat" => 48.41, "lng" => 2.61 } }
      ]
    end

    def poi_routes
      [
        { "id" => 1, "area_id" => 1, "poi_id" => 1, "distance" => 300, "transport" => "walking" }
      ]
    end

    def topos
      [
        { "id" => 42, "area_id" => 1, "published" => true, "photo_path" => "/media/topos/area-1/topo-42.jpg" }
      ]
    end

    def lines
      [
        { "id" => 100, "problem_id" => 10, "topo_id" => 42, "coordinates" => [[0.1, 0.2], [0.3, 0.4], [0.5, 0.6]] }
      ]
    end
  end
end
