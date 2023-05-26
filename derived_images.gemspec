# frozen_string_literal: true

require_relative 'lib/derived_images/version'

Gem::Specification.new do |spec|
  spec.name        = 'derived_images'
  spec.version     = DerivedImages::VERSION
  spec.authors     = ['Michael Kitson']
  spec.homepage    = 'https://github.com/michaelkitson/derived_images'
  spec.license     = 'MIT'
  spec.summary     = 'Programmatically create derived image assets by applying transformations to other assets.'
  spec.description = 'Resize images, lower quality to save bytes, rotate, crop, convert between formats, and anything \
else that the image_processing gem supports.'

  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['lib/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'image_processing', '~> 1.0'
  spec.add_dependency 'listen', '~> 3.0'
  spec.add_dependency 'railties', '>= 6.1'
end
