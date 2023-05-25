# frozen_string_literal: true

module DerivedImages
  # The Manifest creates and holds a list of {ManifestEntry} instances, describing every derived image to create.
  class Manifest
    def initialize(path = Rails.root.join(DerivedImages.config.manifest_path))
      @path = path
      @map = Hash.new { [] }
    end

    def draw(&block)
      @map.clear
      if block
        instance_eval(&block)
      else
        instance_eval(File.read(path), path.to_s)
      end
    end

    def produced_from(source_path)
      source_names = []
      DerivedImages.config.image_paths.each do |path|
        dir = Pathname.new(path).expand_path
        contains_source_file = source_path.ascend.any? { _1 == dir }
        source_names << source_path.relative_path_from(dir).to_s if contains_source_file
      end
      map.values_at(*source_names).flatten
    end

    def each(&block)
      map.each_value { _1.each(&block) }
    end

    ### DSL Functions
    def derive(target, source, &block)
      map[source] <<= ManifestEntry.new(source, target, block ? yield(default_chain) : default_chain)
    end

    def resize(target, source, width, height)
      derive(target, source) { _1.resize_to_limit(width, height) }
    end
    ### End DSL Functions

    attr_reader :path

    private

    attr_reader :map

    def default_chain
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
