# Require ActionView
require File.expand_path('../../../load_paths', __FILE__)
$:.unshift(File.dirname(__FILE__) + '../lib')
require 'action_view'

FIXTURE_ROOT = "#{Pathname.pwd}/test/fixtures"

# Require Dependencies
require 'minitest'
require 'minitest/autorun'
require 'byebug'

def test_tag(block)
  out_file = File.new('test_tag.erb', 'w')
  out_file.puts(block)
  out_file.close

  renderer = ActionView::Renderer.new
  renderer.render(out_file.path)
end
