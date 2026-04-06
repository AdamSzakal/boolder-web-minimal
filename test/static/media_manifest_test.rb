require "test_helper"
require_relative "../../scripts/static/lib/media_manifest"

class Static::MediaManifestTest < ActiveSupport::TestCase
  setup do
    @manifest = Static::MediaManifest.new(
      "topos" => { "42" => "/media/topos/area-12/topo-42.jpg" },
      "area_covers" => { "12" => "/media/area-covers/area-cover-12.jpg" }
    )
  end

  test "topo_url resolves by id" do
    assert_equal "/media/topos/area-12/topo-42.jpg", @manifest.topo_url(42)
  end

  test "area_cover_url resolves by id" do
    assert_equal "/media/area-covers/area-cover-12.jpg", @manifest.area_cover_url(12)
  end

  test "topo_url raises for unknown id" do
    assert_raises(KeyError) { @manifest.topo_url(999) }
  end

  test "builds manifest from catalog topos" do
    topos = [
      { "id" => 1, "area_id" => 5, "published" => true, "photo_path" => "topo-1.jpg" },
      { "id" => 2, "area_id" => 5, "published" => false, "photo_path" => nil }
    ]
    areas = [
      { "id" => 5, "published" => true }
    ]

    manifest = Static::MediaManifest.build(topos: topos, areas: areas)

    assert_equal "/media/topos/area-5/topo-1.jpg", manifest.topo_url(1)
    assert_equal "/media/area-covers/area-cover-5.jpg", manifest.area_cover_url(5)
  end
end
