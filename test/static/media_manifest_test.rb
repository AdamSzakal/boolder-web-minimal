require "test_helper"
require_relative "../../scripts/static/lib/media_manifest"

class Static::MediaManifestTest < Minitest::Test
  def test_topo_url_resolves_from_manifest
    manifest = Static::MediaManifest.new(
      "topos" => { "42" => "https://assets.boolder.com/proxy/topos/42" },
      "area_covers" => {}
    )

    assert_equal "https://assets.boolder.com/proxy/topos/42", manifest.topo_url(42)
  end

  def test_area_cover_url_returns_nil_for_missing_cover
    manifest = Static::MediaManifest.new("topos" => {}, "area_covers" => {})

    assert_nil manifest.area_cover_url(999)
  end

  def test_unknown_topo_id_raises_key_error
    manifest = Static::MediaManifest.new("topos" => {}, "area_covers" => {})

    assert_raises(KeyError) { manifest.topo_url(999) }
  end

  def test_build_factory_creates_manifest_with_cdn_urls
    topos = [{ "id" => 42, "area_id" => 12 }]
    areas = [{ "id" => 5 }]

    manifest = Static::MediaManifest.build(topos: topos, areas: areas)

    assert_equal "https://assets.boolder.com/proxy/topos/42", manifest.topo_url(42)
    assert_nil manifest.area_cover_url(5)
  end
end
