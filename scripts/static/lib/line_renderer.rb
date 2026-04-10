module Static
  class LineRenderer
    COLOR_MAP = {
      "yellow"  => "#FFCC02",
      "purple"  => "#D783FF",
      "orange"  => "#FF9500",
      "green"   => "#77C344",
      "blue"    => "#017AFF",
      "skyblue" => "#5AC7FA",
      "salmon"  => "#FDAF8A",
      "red"     => "#FF3B2F",
      "black"   => "#000000",
      "white"   => "#FFFFFF"
    }.freeze

    IMG_WIDTH = 400
    IMG_HEIGHT = 300

    def self.render_topo_with_line(topo_url:, line:, circuit_color: nil, circuit_number: nil)
      return render_image_only(topo_url) unless line && line["coordinates"].is_a?(Array) && line["coordinates"].size >= 2

      coords = line["coordinates"]
      path_d = bezier_curve(coords)
      hex = COLOR_MAP[circuit_color] || "#FF3B2F"

      # Start dot position
      start_x = (coords.first["x"] * IMG_WIDTH).round(1)
      start_y = (coords.first["y"] * IMG_HEIGHT).round(1)

      # Unique ID for this topo's animation (avoids collisions when multiple topos on a page)
      uid = "topo-#{line["id"] || object_id}"

      <<~HTML
        <div class="topo-wrap">
          <img src="#{escape(topo_url)}" alt="Topo photo" class="topo-img" loading="lazy" />
          <svg class="topo-overlay" viewBox="0 0 #{IMG_WIDTH} #{IMG_HEIGHT}" preserveAspectRatio="none">
            <style>
              @keyframes #{uid}-draw {
                from { stroke-dashoffset: var(--path-length); }
                to   { stroke-dashoffset: 0; }
              }
              @keyframes #{uid}-fade-in {
                from { opacity: 0; }
                to   { opacity: 0.9; }
              }
              ##{uid}-path {
                animation: #{uid}-draw 1.2s ease-out forwards;
              }
              ##{uid}-dot, ##{uid}-label {
                opacity: 0;
                animation: #{uid}-fade-in 0.3s ease-out 1.1s forwards;
              }
            </style>
            <path id="#{uid}-path" d="#{path_d}" fill="none" stroke="#{hex}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" opacity="0.9" />
            <circle id="#{uid}-dot" cx="#{start_x}" cy="#{start_y}" r="8" fill="#{hex}" />
            #{circuit_number_label(start_x, start_y, circuit_number, hex, uid) if circuit_number}
          </svg>
          <script>
            (function() {
              var p = document.getElementById('#{uid}-path');
              if (p) { var l = p.getTotalLength(); p.style.setProperty('--path-length', l); p.style.strokeDasharray = l; p.style.strokeDashoffset = l; }
            })();
          </script>
        </div>
      HTML
    end

    def self.render_image_only(topo_url)
      <<~HTML
        <div class="topo-wrap">
          <img src="#{escape(topo_url)}" alt="Topo photo" class="topo-img" loading="lazy" />
        </div>
      HTML
    end

    # Build an SVG path string with quadratic bezier curves through the points
    def self.bezier_curve(coordinates)
      points = coordinates.map { |c| [c["x"] * IMG_WIDTH, c["y"] * IMG_HEIGHT] }
      return "" if points.size < 2

      parts = ["M #{points[0][0].round(1)} #{points[0][1].round(1)}"]

      if points.size == 2
        parts << "L #{points[1][0].round(1)} #{points[1][1].round(1)}"
      else
        # Quadratic bezier: each point is a control point, midpoints are on-curve
        1.upto(points.size - 2) do |i|
          cx = points[i][0].round(1)
          cy = points[i][1].round(1)
          # Endpoint is midpoint between current control and next control
          if i < points.size - 2
            ex = ((points[i][0] + points[i + 1][0]) / 2.0).round(1)
            ey = ((points[i][1] + points[i + 1][1]) / 2.0).round(1)
          else
            # Last segment ends at the final point
            ex = points[i + 1][0].round(1)
            ey = points[i + 1][1].round(1)
          end
          parts << "Q #{cx} #{cy} #{ex} #{ey}"
        end
      end

      parts.join(" ")
    end

    def self.circuit_number_label(x, y, number, hex, uid = nil)
      id_attr = uid ? %( id="#{uid}-label") : ""
      %(<text#{id_attr} x="#{x}" y="#{y}" text-anchor="middle" dominant-baseline="central" fill="white" font-size="9" font-weight="bold">#{escape(number.to_s)}</text>)
    end

    def self.escape(str)
      str.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
    end
  end
end
