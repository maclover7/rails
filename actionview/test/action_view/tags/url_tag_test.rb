require 'test_helper'

class ActionView::Tags::UrlTagTest < MiniTest::Test
  def test_link_to_tag
    link_to_tag_tests = {
      '<%= link_to("Example", "http://example.com") %>'     => "<a href='http://example.com'>Example</a>",
      '<%= link_to("Example2", "/login") %>'                => "<a href='/login'>Example2</a>",
      '<%= link_to("Example3", "/login", class: "link") %>' => "<a class='link' href='/login'>Example3</a>",
    }

    link_to_tag_tests.each do |method, tag|
      assert_equal(tag, test_tag(method))
    end
  end
end
