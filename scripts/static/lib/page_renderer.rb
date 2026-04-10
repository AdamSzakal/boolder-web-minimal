require "erb"
require "pathname"

module Static
  class PageRenderer
    def initialize(template_root: Pathname("scripts/static/templates"))
      @template_root = template_root
    end

    def render(template_name, locals = {})
      content = render_template(template_name, locals)
      wrap_in_layout(content, locals)
    end

    # Render a standalone template (no layout wrapping) — used for pages with their own full HTML
    def render_standalone(template_name, locals = {})
      render_template(template_name, locals)
    end

    private

    # Render a partial template and return the HTML string.
    # Called from templates as: render_partial("name", key: value)
    def render_partial(name, partial_locals = {})
      path = @template_root.join("_#{name}.html.erb")
      ERB.new(path.read, trim_mode: "-").result(template_binding(partial_locals))
    end

    # Build an ERB binding that exposes locals as variables and includes ViewHelpers
    def render_template(template_name, locals)
      path = @template_root.join("#{template_name}.html.erb")
      ERB.new(path.read, trim_mode: "-").result(template_binding(locals))
    end

    def template_binding(locals)
      # Create a clean binding with access to helpers and partials
      ctx = TemplateContext.new(self, locals)
      ctx.instance_eval { binding }
    end

    def wrap_in_layout(content, locals)
      layout_path = @template_root.join("layout.html.erb")
      layout_locals = locals.merge("content" => content)
      ERB.new(layout_path.read, trim_mode: "-").result(template_binding(layout_locals))
    end
  end

  # Thin context object that makes locals available as methods and
  # exposes ViewHelpers + render_partial to ERB templates.
  class TemplateContext
    def initialize(renderer, locals)
      @_renderer = renderer
      locals.each do |key, value|
        define_singleton_method(key) { value }
      end
    end

    # Delegate ViewHelpers as module methods (called as ViewHelpers.circuit_badge etc.)
    # Also expose frequently used constants directly
    def color_hex;        ViewHelpers::COLOR_HEX;        end
    def steepness_labels; ViewHelpers::STEEPNESS_LABELS;  end

    def render_partial(name, locals = {})
      @_renderer.send(:render_partial, name, locals)
    end
  end
end
