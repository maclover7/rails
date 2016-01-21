require 'test_helper'

class ActionView::Tags::AssetsTagTest < MiniTest::Test
  def test_image_tag
    image_tag_tests = {
      '<%= image_tag("xmlhr.jpg") %>'           => "<img src='/assets/xmlhr.jpg'>",
      '<%= image_tag("xmlhr.png?123") %>'       => "<img src='/assets/xmlhr.png?123'>",
      '<%= image_tag("xmlhr.png?body=1") %>'    => "<img src='/assets/xmlhr.png?body=1'>",
      '<%= image_tag("xmlhr.png#hash") %>'      => "<img src='/assets/xmlhr.png#hash'>",
      '<%= image_tag("xmlhr.png?123#hash") %>'  => "<img src='/assets/xmlhr.png?123#hash'>",
      '<%= image_tag("xmlhr.png", height: "32") %>' => "<img height='32' src='/assets/xmlhr.png'>",
    }

    image_tag_tests.each do |method, tag|
      assert_equal(tag, test_tag(method))
    end

    error = assert_raises ArgumentError do
      test_tag('<%= image_tag("xmlhr") %>')
    end
    assert_equal('Improperly formatted image_tag', error.message)
  end

  def test_javascript_include_tag
    javascript_include_tag_tests = {
      '<%= javascript_include_tag("xmlhr") %>'             => "<script src='/assets/xmlhr.js'></script>",
      '<%= javascript_include_tag("xmlhr.js") %>'          => "<script src='/assets/xmlhr.js'></script>",
      '<%= javascript_include_tag("xmlhr.js?123") %>'      => "<script src='/assets/xmlhr.js?123'></script>",
      '<%= javascript_include_tag("xmlhr.js?body=1") %>'   => "<script src='/assets/xmlhr.js?body=1'></script>",
      '<%= javascript_include_tag("xmlhr.js#hash") %>'     => "<script src='/assets/xmlhr.js#hash'></script>",
      '<%= javascript_include_tag("xmlhr.js?123#hash") %>' => "<script src='/assets/xmlhr.js?123#hash'></script>",
    }

    javascript_include_tag_tests.each do |method, tag|
      assert_equal(tag, test_tag(method))
    end
  end

  def test_stylesheet_link_tag
    stylesheet_link_tag_tests = {
      '<%= stylesheet_link_tag("xmlhr") %>'               => "<link href='/assets/xmlhr.css' rel='stylesheet'>",
      '<%= stylesheet_link_tag("xmlhr.css") %>'           => "<link href='/assets/xmlhr.css' rel='stylesheet'>",
      '<%= stylesheet_link_tag("xmlhr.css?123") %>'       => "<link href='/assets/xmlhr.css?123' rel='stylesheet'>",
      '<%= stylesheet_link_tag("xmlhr.css?body=1") %>'    => "<link href='/assets/xmlhr.css?body=1' rel='stylesheet'>",
      '<%= stylesheet_link_tag("xmlhr.css#hash") %>'      => "<link href='/assets/xmlhr.css#hash' rel='stylesheet'>",
      '<%= stylesheet_link_tag("xmlhr.css?123#hash") %>'  => "<link href='/assets/xmlhr.css?123#hash' rel='stylesheet'>",
      '<%= stylesheet_link_tag("xmlhr", media: "all") %>' => "<link media='all' href='/assets/xmlhr.css' rel='stylesheet'>",
    }

    stylesheet_link_tag_tests.each do |method, tag|
      assert_equal(tag, test_tag(method))
    end
  end
end
