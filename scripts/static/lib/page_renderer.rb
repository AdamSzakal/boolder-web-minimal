require "erb"
require "pathname"

module Static
  class PageRenderer
    def initialize(template_root: Pathname("scripts/static/templates"))
      @template_root = Pathname(template_root)
    end

    def render(template_name, locals)
      content = render_template(template_name, locals)
      render_template("layout", locals.merge("content" => content))
    end

    private

    def render_template(name, locals)
      template_path = @template_root.join("#{name}.html.erb")
      raise "Template not found: #{template_path}" unless template_path.exist?

      template = ERB.new(template_path.read, trim_mode: "-")
      template.result_with_hash(locals)
    end
  end
end
