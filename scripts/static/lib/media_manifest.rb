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

    # Builds a manifest from catalog data using the static export path conventions:
    #   topos:       /media/topos/area-<area_id>/topo-<topo_id>.jpg
    #   area_covers: /media/area-covers/area-cover-<area_id>.jpg
    def self.build(topos:, areas:)
      topo_entries = topos
        .select { |t| t["published"] }
        .each_with_object({}) do |topo, hash|
          hash[topo["id"].to_s] = "/media/topos/area-#{topo['area_id']}/topo-#{topo['id']}.jpg"
        end

      cover_entries = areas
        .select { |a| a["published"] }
        .each_with_object({}) do |area, hash|
          hash[area["id"].to_s] = "/media/area-covers/area-cover-#{area['id']}.jpg"
        end

      new("topos" => topo_entries, "area_covers" => cover_entries)
    end
  end
end
