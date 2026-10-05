# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'rails', '>= 6.1'
gem 'rubocop', '~> 1.51'
gem 'rubocop-performance', '~> 1.17'

# Rubies before 3.1 are stuck on Rails < 7.2, whose ActiveSupport passes
# JSON.generate options that json 3 removed.
gem 'json', '< 3' if RUBY_VERSION < '3.1'
