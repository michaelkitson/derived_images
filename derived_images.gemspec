# frozen_string_literal: true

require_relative 'lib/derived_images/version'

Gem::Specification.new do |spec|
  spec.name        = 'derived_images'
  spec.version     = DerivedImages::VERSION
  spec.authors     = ['Michael Kitson']
  spec.homepage    = 'https://github.com/michaelkitson/derived_images'
  spec.summary     = 'Summary of DerivedImages.'
  spec.description = 'Description of DerivedImages.'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'image_processing', '~> 1.0'
  spec.add_dependency 'listen', '~> 3.0'
  spec.add_dependency 'rails', '>= 6.1'
end
