# frozen_string_literal: true

module DerivedImages
  # A ManifestEntry describes how to create one derived image.
  class ManifestEntry
    attr_accessor :source, :target, :pipeline

    def initialize(source, target)
      @source = source
      @target = target
      @pipeline = default_pipeline(File.extname(target))
    end

    def ==(other)
      source == other.source && target == other.target && options_hash == other.options_hash
    end

    def source_path
      DerivedImages.config.image_paths.each do |path|
        path = Pathname.new(path).join(source).expand_path
        return path if path.file?
      end
      nil
    end

    def target_path
      Pathname.new(DerivedImages.config.build_path).join(target).expand_path
    end

    # Returns a cache key for the result of the image transformation. It will vary if the source file's content varies
    # or if the operations applied to generate the target vary.
    #
    # @return [String, nil] A 64 character hexdigest, or nil if the source file can't be found
    def cache_key
      return nil unless source_present?

      Digest::SHA256.hexdigest({ source: source_digest, pipeline: options_hash }.to_json)
    end

    def self.empty_pipeline
      PROCESSORS.fetch(DerivedImages.config.processor).dup
    end

    PROCESSORS = { mini_magick: ImageProcessing::MiniMagick, vips: ImageProcessing::Vips }.freeze
    COMPRESSION_OVERRIDES = { 'avif' => 'av1', 'heic' => 'hevc' }.freeze

    def target_digest
      Digest::SHA256.file(target_path).hexdigest
    end

    def source_present?
      source_path&.file?
    end

    private

    def source_digest
      Digest::SHA256.file(source_path).hexdigest
    end

    def default_pipeline(target_ext)
      pipeline = PROCESSORS.fetch(DerivedImages.config.processor).dup
      pipeline = pipeline.convert(target_ext) if target_ext.present?
      vips = pipeline.options[:processor] == ImageProcessing::Vips::Processor
      if vips && !Vips.at_least_libvips?(8, 12) && COMPRESSION_OVERRIDES.key?(target_ext)
        # https://github.com/libvips/libvips/commit/47383b5bfc136f7870c319a1edce4848e177425b
        pipeline = pipeline.saver(compression: COMPRESSION_OVERRIDES.fetch(target_ext))
      end
      pipeline
    end

    protected

    def options_hash
      pipeline.branch.options
    end
  end
end
