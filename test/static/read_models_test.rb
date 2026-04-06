require "test_helper"
require_relative "../../scripts/static/lib/source_catalog"
require_relative "../../scripts/static/lib/read_models"

class Static::ReadModelsTest < ActiveSupport::TestCase
  class FakeCatalog
    def areas
      [
        { "id" => 1, "slug" => "franchard-isatis", "name" => "Franchard Isatis", "published" => true, "priority" => 1, "tags" => ["popular"], "problems_count" => 3 },
        { "id" => 2, "slug" => "cul-de-chien", "name" => "Cul de Chien", "published" => true, "priority" => 1, "tags" => [], "problems_count" => 1 },
        { "id" => 99, "slug" => "unpublished", "name" => "Unpublished", "published" => false, "priority" => 0, "tags" => [], "problems_count" => 0 }
      ]
    end

    def problems
      [
        { "id" => 10, "area_id" => 1, "name" => "Carnage", "grade" => "7b", "steepness" => "overhang", "sit_start" => false, "featured" => true, "popularity" => 90, "circuit_id" => nil, "circuit_number" => nil, "circuit_color" => nil, "parent_id" => nil, "bleau_info_id" => "123", "location" => { "lat" => 48.4, "lng" => 2.6 } },
        { "id" => 11, "area_id" => 1, "name" => "La Marie-Rose", "grade" => "6a", "steepness" => "slab", "sit_start" => false, "featured" => true, "popularity" => 95, "circuit_id" => 1, "circuit_number" => "5", "circuit_color" => "red", "parent_id" => nil, "bleau_info_id" => nil, "location" => { "lat" => 48.4, "lng" => 2.6 } },
        { "id" => 12, "area_id" => 1, "name" => "Easy One", "grade" => "3a", "steepness" => "wall", "sit_start" => false, "featured" => false, "popularity" => 50, "circuit_id" => 1, "circuit_number" => "4", "circuit_color" => "red", "parent_id" => nil, "bleau_info_id" => nil, "location" => { "lat" => 48.4, "lng" => 2.6 } },
        { "id" => 13, "area_id" => 1, "name" => "Carnage Assis", "grade" => "7c", "steepness" => "overhang", "sit_start" => true, "featured" => false, "popularity" => 30, "circuit_id" => nil, "circuit_number" => nil, "circuit_color" => nil, "parent_id" => 10, "bleau_info_id" => nil, "location" => { "lat" => 48.4, "lng" => 2.6 } },
        { "id" => 14, "area_id" => 1, "name" => "Red 6", "grade" => "5a", "steepness" => "wall", "sit_start" => false, "featured" => false, "popularity" => 10, "circuit_id" => 1, "circuit_number" => "6", "circuit_color" => "red", "parent_id" => nil, "bleau_info_id" => nil, "location" => { "lat" => 48.4, "lng" => 2.6 } },
        { "id" => 20, "area_id" => 2, "name" => "Gentle", "grade" => "4a", "steepness" => "slab", "sit_start" => false, "featured" => false, "popularity" => 40, "circuit_id" => nil, "circuit_number" => nil, "circuit_color" => nil, "parent_id" => nil, "bleau_info_id" => nil, "location" => { "lat" => 48.4, "lng" => 2.6 } }
      ]
    end

    def circuits
      [
        { "id" => 1, "color" => "red", "average_grade" => "5a", "beginner_friendly" => false, "dangerous" => false, "main_area_id" => 1, "main_area_name" => "Franchard Isatis" }
      ]
    end

    def clusters
      []
    end

    def pois
      [
        { "id" => 1, "poi_type" => "parking", "name" => "Parking Isatis", "short_name" => "Isatis", "google_url" => "https://maps.google.com/test", "location" => { "lat" => 48.4, "lng" => 2.6 } }
      ]
    end

    def poi_routes
      [
        { "id" => 1, "area_id" => 1, "poi_id" => 1, "distance" => 200, "transport" => "walking" }
      ]
    end

    def topos
      [
        { "id" => 42, "area_id" => 1, "boulder_id" => 100, "position" => 1, "published" => true }
      ]
    end

    def lines
      [
        { "id" => 1, "problem_id" => 10, "topo_id" => 42, "coordinates" => [{ "x" => 0.3, "y" => 0.8 }, { "x" => 0.3, "y" => 0.5 }, { "x" => 0.3, "y" => 0.2 }] }
      ]
    end
  end

  setup do
    @models = Static::ReadModels.new(FakeCatalog.new)
  end

  test "area_page returns area, popular_problems, circuits, and poi_routes" do
    payload = @models.area_page("franchard-isatis")

    assert_equal "Franchard Isatis", payload["area"]["name"]
    assert payload["popular_problems"].any?
    assert payload["circuits"].any?
    assert payload["poi_routes"].all? { |r| r.key?("transport") }
  end

  test "popular_problems are sorted by grade desc then popularity desc" do
    payload = @models.area_page("franchard-isatis")
    grades = payload["popular_problems"].map { |p| p["grade"] }

    # 7c (Carnage Assis, pop 30), 7b (Carnage, pop 90), 6a (Marie-Rose, pop 95), ... — grade desc
    assert_equal "7c", grades.first
  end

  test "problem_page returns all expected fields" do
    payload = @models.problem_page(10)

    assert_equal "Carnage", payload["problem"]["name"]
    assert_equal "Franchard Isatis", payload["area"]["name"]
    assert_not_nil payload["line"]
    assert_not_nil payload["topo"]
    assert payload["variants"].any? { |v| v["name"] == "Carnage Assis" }
  end

  test "problem_page includes circuit navigation" do
    payload = @models.problem_page(11)

    assert_equal "red", payload["circuit"]["color"]
    assert_equal "Easy One", payload["circuit_previous"]["name"]
    assert_equal "Red 6", payload["circuit_next"]["name"]
  end

  test "all_areas returns published areas sorted by name" do
    areas = @models.all_areas
    names = areas.map { |a| a["name"] }

    assert_includes names, "Cul de Chien"
    assert_includes names, "Franchard Isatis"
    refute_includes names, "Unpublished"
    assert_equal names, names.sort_by(&:downcase)
  end
end
