# frozen_string_literal: true

module DerivedImages
  # A ManifestEntry describes how to create one derived image.
  class ManifestEntry
    attr_accessor :source, :target, :pipeline

    def initialize(source, target, pipeline)
      @source = source
      @target = target
      @pipeline = pipeline
    end

    def source_path
      DerivedImages.config.image_paths.each do |path|
        path = Pathname.new(path).join(source).expand_path
        return path if path.file?
      end
    end

    def target_path
      Pathname.new(DerivedImages.config.build_path).join(target).expand_path
    end

    def self.empty_pipeline
      case type = DerivedImages.config.processor
      when :mini_magick
        ImageProcessing::MiniMagick
      when :vips
        ImageProcessing::Vips
      else
        raise "Unknown derived_images processor type #{type}"
      end
    end
  end
end
