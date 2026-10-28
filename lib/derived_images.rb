# frozen_string_literal: true

require 'etc'
require 'image_processing'
require 'listen'
require 'rails'

require 'derived_images/cache'
require 'derived_images/dsl'
require 'derived_images/format_support'
require 'derived_images/manifest'
require 'derived_images/manifest_entry'
require 'derived_images/processor'
require 'derived_images/railtie'
require 'derived_images/worker'
require 'derived_images/version'

# DerivedImages programmatically creates derived image assets by applying transformations to other assets.
module DerivedImages
  # Raised by {Processor#run_once} when one or more images couldn't be built.
  class BuildError < StandardError; end

  def self.config
    Rails.application.config.derived_images
  end
end
