require "test_helper"
require_relative "../../scripts/static/lib/media_manifest"

class Static::MediaManifestTest < ActiveSupport::TestCase
  test "topo_url resolves from manifest" do
    manifest = Static::MediaManifest.new(
      "topos" => { "42" => "/media/topos/area-12/topo-42.jpg" },
      "area_covers" => {}
    )

    assert_equal "/media/topos/area-12/topo-42.jpg", manifest.topo_url(42)
  end

  test "area_cover_url resolves from manifest" do
    manifest = Static::MediaManifest.new(
      "topos" => {},
      "area_covers" => { "5" => "/media/area-covers/area-cover-5.jpg" }
    )

    assert_equal "/media/area-covers/area-cover-5.jpg", manifest.area_cover_url(5)
  end

  test "unknown id raises KeyError" do
    manifest = Static::MediaManifest.new("topos" => {}, "area_covers" => {})

    assert_raises(KeyError) { manifest.topo_url(999) }
  end

  test "build factory creates manifest from topos and areas" do
    topos = [{ "id" => 42, "area_id" => 12 }]
    areas = [{ "id" => 5 }]

    manifest = Static::MediaManifest.build(topos: topos, areas: areas)

    assert_equal "/media/topos/area-12/topo-42.jpg", manifest.topo_url(42)
    assert_equal "/media/area-covers/area-cover-5.jpg", manifest.area_cover_url(5)
  end
end
