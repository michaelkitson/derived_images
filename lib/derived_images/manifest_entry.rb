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

    # Returns a cache key for the result of the image transformation. It will vary if the source file's content varies
    # or if the operations applied to generate the target vary.
    #
    # @return [String] A 64 character hexdigest
    def cache_key
      Digest::SHA256.hexdigest({ source: source_digest, pipeline: pipeline.options }.to_json)
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

    private

    def source_digest
      Digest::SHA256.file(source_path).hexdigest
    end
  end
end
