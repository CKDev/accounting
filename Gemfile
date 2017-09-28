source 'https://rubygems.org'
source 'https://gem.minow.io' do
  # Stupid, but Authorize.NET fails to maintain their own gem
  # so we have to do it separately
  gem 'authorizenet', path: '/web/Gems/sdk-ruby' #'~> 1.9.4'
end

# Specify your gem's dependencies in accounting.gemspec
gemspec

group :development, :test do
  gem 'byebug'
  gem 'ffaker'
end

group :test do
  gem 'coveralls', require: false
  gem 'webmock', '~> 3'
  gem 'vcr'
end