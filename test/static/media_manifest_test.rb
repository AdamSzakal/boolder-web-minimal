require "test_helper"
require_relative "../../scripts/static/lib/media_manifest"

class Static::MediaManifestTest < ActiveSupport::TestCase
  test "topo_url resolves from manifest" do
    manifest = Static::MediaManifest.new(
      "topos" => { "42" => "https://assets.boolder.com/proxy/topos/42" },
      "area_covers" => {}
    )

    assert_equal "https://assets.boolder.com/proxy/topos/42", manifest.topo_url(42)
  end

  test "area_cover_url returns nil for missing cover" do
    manifest = Static::MediaManifest.new("topos" => {}, "area_covers" => {})

    assert_nil manifest.area_cover_url(999)
  end

  test "unknown topo id raises KeyError" do
    manifest = Static::MediaManifest.new("topos" => {}, "area_covers" => {})

    assert_raises(KeyError) { manifest.topo_url(999) }
  end

  test "build factory creates manifest with CDN URLs" do
    topos = [{ "id" => 42, "area_id" => 12 }]
    areas = [{ "id" => 5 }]

    manifest = Static::MediaManifest.build(topos: topos, areas: areas)

    assert_equal "https://assets.boolder.com/proxy/topos/42", manifest.topo_url(42)
    assert_nil manifest.area_cover_url(5)
  end
end
