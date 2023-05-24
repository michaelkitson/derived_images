# frozen_string_literal: true

require 'image_processing'
require 'listen'

require 'derived_images/version'
require 'derived_images/manifest'
require 'derived_images/manifest_entry'
require 'derived_images/processor'
require 'derived_images/railtie'
require 'derived_images/worker'

module DerivedImages
  def self.config
    Rails.application.config.derived_images
  end
end
