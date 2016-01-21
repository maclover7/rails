version = File.read(File.expand_path("../../RAILS_VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'actionview'
  s.version     = version
  s.summary     = 'Rendering framework putting the V in MVC (part of Rails).'
  s.description = 'Simple, battle-tested conventions and helpers for building web pages.'

  s.required_ruby_version = '>= 2.2.2'

  s.license     = 'MIT'

  s.author            = 'David Heinemeier Hansson'
  s.email             = 'david@loudthinking.com'
  s.homepage          = 'http://www.rubyonrails.org'

  s.files        = Dir['CHANGELOG.md', 'README.rdoc', 'MIT-LICENSE', 'lib/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'activesupport'
  s.add_dependency 'tilt'
end
