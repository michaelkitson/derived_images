# frozen_string_literal: true

module DerivedImages
  # Use these DSL functions in your `config/derived_images.rb` file to define images to derive.
  #
  # @note An image format conversions can be automatically inferred from the `target` file extension in these methods.
  module Dsl
    # Resize an image, preserving its aspect ratio.
    #
    # @param [String] target The relative file name of the target (derived) image
    # @param [String] source The relative file name of the source image. Must be in one of the configured `image_paths`
    # @param [Integer] width The max width of the derived image
    # @param [Integer] height The max height of the derived image
    # @return [ManifestEntry]
    def resize(target, source, width, height)
      derive(target, source) { _1.resize_to_limit(width, height) }
    end

    # Derive one image from another, with full customization abilities.
    #
    # @param [String] target The relative file name of the target (derived) image
    # @param [String] source The relative file name of the source image. Must be in one of the configured `image_paths`
    # @yieldparam pipeline [ImageProcessing::Chainable] The pipeline you can use to further customize the transformation
    # @return [ManifestEntry]
    def derive(target, source, &block)
      pipeline = ManifestEntry.empty_pipeline
      pipeline = yield(pipeline) if block
      map[target] = ManifestEntry.new(source, target, pipeline)
    end
  end
end
