require 'test_helper'

class ActionView::VersionTest < MiniTest::Test
  def test_gem_version_is_a_gem_version
    assert_instance_of(Gem::Version, ActionView.gem_version)
  end

  def test_version_string_equal_to_gem_version
    assert_equal(ActionView::VERSION::STRING, ActionView.gem_version.to_s)
  end
end
