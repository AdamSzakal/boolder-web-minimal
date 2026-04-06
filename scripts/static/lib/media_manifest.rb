module Static
  class MediaManifest
    def initialize(data)
      @data = data
    end

    def topo_url(id)
      @data.fetch("topos").fetch(id.to_s)
    end

    def area_cover_url(id)
      @data.fetch("area_covers").fetch(id.to_s)
    end

    # Build manifest from catalog data using path conventions
    def self.build(topos:, areas:)
      topo_map = topos.each_with_object({}) do |t, h|
        h[t["id"].to_s] = "/media/topos/area-#{t['area_id']}/topo-#{t['id']}.jpg"
      end

      cover_map = areas.each_with_object({}) do |a, h|
        h[a["id"].to_s] = "/media/area-covers/area-cover-#{a['id']}.jpg"
      end

      new("topos" => topo_map, "area_covers" => cover_map)
    end
  end
end
