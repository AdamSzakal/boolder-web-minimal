module Static
  class LineRenderer
    COLOR_MAP = {
      "yellow" => "#FFCC02", "purple" => "#D783FF", "orange" => "#FF9500",
      "green" => "#77C344", "blue" => "#017AFF", "skyblue" => "#5AC7FA",
      "salmon" => "#FDAF8A", "red" => "#FF3B2F", "black" => "#000000",
      "white" => "#FFFFFF"
    }.freeze

    # Renders an SVG overlay for a line on a topo image.
    # Returns an HTML string with the topo image and SVG line overlay.
    def self.render_topo_with_line(topo_url:, line:, circuit_color: nil, circuit_number: nil)
      coordinates = line["coordinates"]
      return render_image_only(topo_url) unless coordinates && coordinates.length >= 2

      stroke_color = COLOR_MAP[circuit_color] || "#000000"
      text_color = circuit_color == "white" ? "#333" : "#FFF"
      path_d = bezier_curve(coordinates)

      # Starting circle position
      first = coordinates.first
      cx = first["x"] || first[0]
      cy = first["y"] || first[1]

      <<~HTML
        <div class="relative">
          <img src="#{topo_url}" alt="Topo" class="w-full sm:rounded-lg">
          <div class="absolute top-0 left-0 w-full h-full pointer-events-none">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300" class="w-full h-full" style="filter: drop-shadow(0px 0px 8px rgba(0.2,0.2,0.2,0.6));">
              <path d="#{path_d}" stroke="#{stroke_color}" stroke-linecap="round" stroke-width="3" fill="none"/>
            </svg>
          </div>
          <div class="absolute" style="left:#{(cx * 100).round(2)}%; top:#{(cy * 100).round(2)}%;">
            <div class="absolute" style="top:-12px; left:-12px;">
              <span class="rounded-full h-6 w-6 leading-6 inline-flex justify-center text-sm" style="background-color: #{stroke_color}; color: #{text_color};">#{circuit_number || "&nbsp;"}</span>
            </div>
          </div>
        </div>
      HTML
    end

    def self.render_image_only(topo_url)
      <<~HTML
        <div class="relative">
          <img src="#{topo_url}" alt="Topo" class="w-full sm:rounded-lg">
        </div>
      HTML
    end

    # Port of the JS bezierCurve() method from topo_line_controller.js
    def self.bezier_curve(coordinates)
      points = coordinates.map do |point|
        x = point["x"] || point[0]
        y = point["y"] || point[1]
        { x: (x * 400).round, y: (y * 300).round }
      end

      return "" if points.length < 2

      if points.length == 2
        return "M #{points[0][:x]} #{points[0][:y]} L #{points[1][:x]} #{points[1][:y]}"
      end

      path = "M #{points[0][:x]} #{points[0][:y]} Q"

      (1...(points.length - 2)).each do |i|
        xc = ((points[i][:x] + points[i + 1][:x]) / 2.0).round
        yc = ((points[i][:y] + points[i + 1][:y]) / 2.0).round
        path += " #{points[i][:x]} #{points[i][:y]} #{xc} #{yc}"
      end

      i = points.length - 2
      path += " #{points[i][:x]} #{points[i][:y]} #{points[i + 1][:x]} #{points[i + 1][:y]}"

      path
    end
  end
end
