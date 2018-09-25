# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'keepasshttp'

Gem::Specification.new do |spec|
  spec.name          = 'keepasshttp'
  spec.version       = Keepasshttp::VERSION
  spec.authors       = ['Holger Arndt']
  spec.email         = ['holger.arndt@hetzner.com']

  spec.summary       = 'Ruby client for keepasshttp'
  spec.description   = 'A client for https://github.com/pfn/keepasshttp to ' \
                       'fetch passwords'
  spec.homepage      = 'https://github.com/Kjarrigan/keepasshttp-ruby'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
