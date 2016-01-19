# Require ActionView
require File.expand_path('../../../load_paths', __FILE__)
$:.unshift(File.dirname(__FILE__) + '../lib')
require 'action_view'

# Require Dependencies
require 'minitest'
require 'minitest/autorun'
