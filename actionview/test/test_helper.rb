# Require ActionView
require File.expand_path('../../../load_paths', __FILE__)
$:.unshift(File.dirname(__FILE__) + '../lib')
require 'action_view'

FIXTURE_ROOT = "#{Pathname.pwd}/test/fixtures"

# Require Dependencies
require 'minitest'
require 'minitest/autorun'
