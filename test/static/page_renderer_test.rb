require "test_helper"
require_relative "../../scripts/static/lib/page_renderer"

class Static::PageRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = Static::PageRenderer.new(
      template_root: Pathname("scripts/static/templates")
    )
  end

  test "renders a template with locals" do
    topo_html = '<div class="relative"><img src="/media/topos/area-12/topo-42.jpg" alt="Topo" class="w-full sm:rounded-lg"></div>'
    html = @renderer.render("problems/show", {
      "problem" => { "name" => "Carnage", "grade" => "7b", "id" => 10 },
      "area" => { "name" => "Franchard Isatis", "slug" => "franchard-isatis" },
      "topo" => { "photo_path" => "/media/topos/area-12/topo-42.jpg" },
      "topo_html" => topo_html,
      "line" => { "coordinates" => [[0.1, 0.2]] },
      "variants" => [],
      "circuit" => nil,
      "circuit_previous" => nil,
      "circuit_next" => nil,
      "locale" => "en"
    })

    assert_includes html, "Carnage"
    assert_includes html, "7b"
    assert_includes html, "/media/topos/area-12/topo-42.jpg"
  end

  test "renders layout around content" do
    html = @renderer.render("problems/show", {
      "problem" => { "name" => "Test", "grade" => "5a", "id" => 1 },
      "area" => { "name" => "Test Area", "slug" => "test-area" },
      "topo" => nil,
      "topo_html" => "",
      "line" => nil,
      "variants" => [],
      "circuit" => nil,
      "circuit_previous" => nil,
      "circuit_next" => nil,
      "locale" => "en"
    })

    assert_includes html, "<!DOCTYPE html>"
    assert_includes html, "Boolder"
  end
end
