require "erb"
require "pathname"

module Static
  class PageRenderer
    def initialize(template_root: Pathname("scripts/static/templates"))
      @template_root = template_root
    end

    def render(template_name, locals = {})
      template_path = @template_root.join("#{template_name}.html.erb")
      content = ERB.new(template_path.read, trim_mode: "-").result_with_hash(locals)
      wrap_in_layout(content, locals)
    end

    # Render a standalone template (no layout wrapping) — used for pages with their own full HTML
    def render_standalone(template_name, locals = {})
      template_path = @template_root.join("#{template_name}.html.erb")
      ERB.new(template_path.read, trim_mode: "-").result_with_hash(locals)
    end

    private

    def wrap_in_layout(content, locals)
      layout_path = @template_root.join("layout.html.erb")
      layout_locals = locals.merge("content" => content)
      ERB.new(layout_path.read, trim_mode: "-").result_with_hash(layout_locals)
    end
  end
end
