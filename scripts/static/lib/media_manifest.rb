module Static
  class MediaManifest
    TOPO_CDN_BASE = "https://assets.boolder.com/proxy/topos"

    def initialize(data)
      @data = data
    end

    def topo_url(id)
      @data.fetch("topos").fetch(id.to_s)
    end

    def area_cover_url(id)
      @data.dig("area_covers", id.to_s)
    end

    # Build manifest using CDN URLs for topos (no local media needed)
    def self.build(topos:, areas:)
      topo_map = topos.each_with_object({}) do |t, h|
        h[t["id"].to_s] = "#{TOPO_CDN_BASE}/#{t['id']}"
      end

      new("topos" => topo_map, "area_covers" => {})
    end
  end
end
