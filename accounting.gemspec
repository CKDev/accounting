# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'accounting/version'

Gem::Specification.new do |spec|
  spec.name          = 'accounting'
  spec.version       = Accounting::VERSION
  spec.authors       = ['Eric Hainer']
  spec.email         = ['eric@commercekitchen.com']

  spec.summary       = %q{Authorize.NET Accounting Integration}
  spec.homepage      = 'https://www.github.com/ehainer/accounting'
  spec.license       = 'GPL-3.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '~> 5'
  spec.add_dependency 'credit_card_validator', '~> 1'
  spec.add_dependency 'bigdecimal', '>= 1.3.2'
  spec.add_dependency 'htmlentities', '~> 4.3'
  spec.add_dependency 'hooks', '~> 0.4.1'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 11.3'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rspec-rails', '~> 3.6.1'
  spec.add_development_dependency 'factory_girl_rails', '~> 4.7'
  spec.add_development_dependency 'sqlite3', '~> 1'
  spec.add_development_dependency 'sidekiq', '~> 4.2.10'
  spec.add_development_dependency 'colorize', '~> 0.8.1'
  spec.add_development_dependency 'pg', '~> 0.18'
  spec.add_development_dependency 'pry'
end
