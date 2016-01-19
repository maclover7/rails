require 'test_helper'

class ActionView::RendererTest < MiniTest::Test
  def test_render_static_template
    template_file = Pathname.new("#{FIXTURE_ROOT}/templates/static.html.erb")
    renderer = ActionView::Renderer.new
    result = renderer.render(template_file)

    assert_equal('hello', result)
  end

  def test_render_dynamic_template
    template_file = Pathname.new("#{FIXTURE_ROOT}/templates/dynamic.html.erb")
    renderer = ActionView::Renderer.new
    result = renderer.render(template_file, { name: 'Rails' })
    assert_equal('Rails is cool', result)
  end
end
