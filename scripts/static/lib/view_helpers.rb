module Static
  module ViewHelpers
    COLOR_HEX = {
      "yellow"  => "#FFCC02",
      "purple"  => "#D783FF",
      "orange"  => "#FF9500",
      "green"   => "#77C344",
      "blue"    => "#017AFF",
      "skyblue" => "#5AC7FA",
      "salmon"  => "#FDAF8A",
      "red"     => "#FF3B2F",
      "black"   => "#000000",
      "white"   => "#FFFFFF",
    }.freeze

    STEEPNESS_LABELS = {
      "wall"     => "Wall",
      "slab"     => "Slab",
      "overhang" => "Overhang",
      "roof"     => "Roof",
      "traverse" => "Traverse",
      "other"    => "Other",
    }.freeze

    # Text color that contrasts with the circuit background
    def self.circuit_text_color(color)
      color == "white" ? "#000" : "#FFF"
    end

    def self.circuit_hex(color)
      COLOR_HEX[color] || "#999"
    end

    # Colored pill badge for a circuit (e.g. "Orange 12")
    def self.circuit_badge(color, number = nil, size: :sm)
      hex = circuit_hex(color)
      text = circuit_text_color(color)

      case size
      when :sm
        label = color.capitalize
        label += " #{number}" if number
        %(<span class="badge badge--circuit" style="background-color: #{hex}; color: #{text};">#{label}</span>)
      when :dot
        content = number || "&nbsp;"
        %(<span class="badge--circuit-dot" style="background-color: #{hex}; color: #{text};">#{content}</span>)
      end
    end

    # Gray pill badge (popularity, steepness, area name, distance, etc.)
    def self.metadata_badge(content, icon: nil)
      inner = icon ? "#{icon} #{content}" : content
      %(<span class="badge badge--meta">#{inner}</span>)
    end

    # Breadcrumb separator chevron
    BREADCRUMB_SEP = %(<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>).freeze

    # Build breadcrumb HTML from an array of [label, url] pairs
    def self.breadcrumb(*links)
      parts = links.map { |label, url| %(<div><a href="#{url}">#{label}</a></div>) }
      %(<div class="breadcrumb">#{parts.join(BREADCRUMB_SEP)}</div>)
    end

    # SVG icons referenced in multiple templates
    ICON_DANGER = %(<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>).freeze

    ICON_BEGINNER = %(<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>).freeze

    ICON_HEART = %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z"/></svg>).freeze

    ICON_MAP_PIN = %(<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>).freeze

    ICON_EXTERNAL = %(<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/></svg>).freeze

    ICON_CIRCUIT = %(<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 9l3 3m0 0l-3 3m3-3H8m13 0a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>).freeze

    # Action link (icon + label)
    def self.action_link(href, icon, label, rel: nil, target: nil)
      attrs = %( href="#{href}")
      attrs += %( rel="#{rel}") if rel
      attrs += %( target="#{target}") if target
      %(<a#{attrs} class="action-link">#{icon}<div>#{label}</div></a>)
    end

    # Circuit status icons (danger + beginner badges)
    def self.circuit_status_icons(circuit, icon_size: :lg)
      parts = []
      if circuit["dangerous"]
        parts << %(<span class="circuit-status-icon circuit-status-icon--danger" title="Dangerous">#{ICON_DANGER}</span>)
      end
      if circuit["beginner_friendly"]
        parts << %(<span class="circuit-status-icon circuit-status-icon--beginner" title="Beginner friendly">#{ICON_BEGINNER}</span>)
      end
      parts.join
    end

    # Generate a URL-friendly slug for a problem
    def self.problem_slug(problem)
      [problem["id"], problem["name"]&.downcase&.gsub(/[^a-z0-9]+/, "-")&.gsub(/-$/, "")].compact.join("-")
    end

    # JSON color map for embedding in <script> tags — single source of truth for JS
    def self.color_hex_json
      COLOR_HEX.to_json
    end

    def self.steepness_labels_json
      STEEPNESS_LABELS.to_json
    end
  end
end
