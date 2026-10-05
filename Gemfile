# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Set RAILS_VERSION (e.g. '~> 7.0.0') to test against a specific Rails; defaults to the newest the Ruby supports.
rails_version = ENV['RAILS_VERSION'].to_s
gem 'rails', rails_version.empty? ? '>= 7.0' : rails_version
gem 'rubocop', '~> 1.51'
gem 'rubocop-performance', '~> 1.17'

# Rails 7.0, 7.1 and 8.0 (and all that Rubies before 3.1 can install) pass JSON.generate options that json 3 removed.
gem 'json', '< 3' if RUBY_VERSION < '3.1' || rails_version.match?(/\b(7\.[01]|8\.0)/)

# Rails 7.0 relies on Logger being loaded implicitly, which concurrent-ruby 1.3.5+ stopped doing.
gem 'concurrent-ruby', '< 1.3.5' if rails_version.match?(/\b7\.0/)

# ffi 1.17+ requires Ruby 3.0; Ruby 2.7's bundler picks it anyway for the musl platform variant.
gem 'ffi', '< 1.17' if RUBY_VERSION < '3.0'
