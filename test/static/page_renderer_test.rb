require "test_helper"
require_relative "../../scripts/static/lib/page_renderer"

class Static::PageRendererTest < ActiveSupport::TestCase
  test "renders template with locals" do
    # Create a minimal temp template for testing
    dir = Dir.mktmpdir
    template_dir = Pathname(dir)

    # Layout that just wraps content
    File.write(template_dir.join("layout.html.erb"), <<~ERB)
      <!DOCTYPE html>
      <html>
      <head><title>Boolder</title></head>
      <body><%= content %></body>
      </html>
    ERB

    # Problem template
    FileUtils.mkdir_p(template_dir.join("problems"))
    File.write(template_dir.join("problems", "show.html.erb"), <<~ERB)
      <h1><%= problem["name"] %> — <%= problem["grade"] %></h1>
      <%= topo_html %>
    ERB

    renderer = Static::PageRenderer.new(template_root: template_dir)
    html = renderer.render("problems/show",
      "problem" => { "name" => "Carnage", "grade" => "7b" },
      "topo_html" => '<img src="/media/topos/area-12/topo-42.jpg" />'
    )

    assert_includes html, "Carnage"
    assert_includes html, "7b"
    assert_includes html, "/media/topos/area-12/topo-42.jpg"
  ensure
    FileUtils.remove_entry(dir) if dir
  end

  test "renders layout around content" do
    dir = Dir.mktmpdir
    template_dir = Pathname(dir)

    File.write(template_dir.join("layout.html.erb"), <<~ERB)
      <!DOCTYPE html>
      <html>
      <head><title>Boolder</title></head>
      <body><%= content %></body>
      </html>
    ERB

    File.write(template_dir.join("simple.html.erb"), "<p>Hello</p>")

    renderer = Static::PageRenderer.new(template_root: template_dir)
    html = renderer.render("simple")

    assert_includes html, "<!DOCTYPE html>"
    assert_includes html, "Boolder"
    assert_includes html, "<p>Hello</p>"
  ensure
    FileUtils.remove_entry(dir) if dir
  end
end
