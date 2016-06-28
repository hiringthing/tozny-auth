# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tozny/auth/version'

Gem::Specification.new do |spec|
  spec.name          = 'tozny-auth'
  spec.version       = Tozny::Auth::VERSION
  spec.authors       = ['Ethan Bell / emanb29']
  spec.email         = ['eb@ethanbell.me']
  spec.license       = 'Apache-2.0'

  spec.summary       = %q{Tozny Ruby SDK}
  spec.description   = %q{A set of methods to more conveniently access the Tozny authentication API as a RP of Tozny from Ruby}
  spec.homepage      = 'https://github.com/tozny/sdk-ruby'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = 'TODO: What should this be???'
  # else
  #   raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency  'rubocop', '~> 0.41.1'

  # Only with ruby 2.0.x
  spec.required_ruby_version = '~> 2'
end
