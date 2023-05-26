# frozen_string_literal: true

module DerivedImages
  # The Manifest creates and holds a list of {ManifestEntry} instances, describing every derived image to create.
  class Manifest
    include Dsl

    def initialize(path = Rails.root.join(DerivedImages.config.manifest_path))
      @path = path
      @map = {}
    end

    def draw(&block)
      @map.clear
      if block
        instance_eval(&block)
      else
        instance_eval(File.read(path), path.to_s)
      end
    end

    def add_entry(entry)
      map[entry.target] = entry
    end

    delegate :[], :count, :each, :each_value, :key?, :length, to: :map

    def produced_from(source_path)
      source_names = []
      DerivedImages.config.image_paths.each do |path|
        dir = Pathname.new(path).expand_path
        contains_source_file = source_path.ascend.any? { _1 == dir }
        source_names << source_path.relative_path_from(dir).to_s if contains_source_file
      end
      map.filter_map { |_target, entry| source_names.include?(entry.source) ? entry : nil }
    end

    attr_reader :path

    private

    attr_reader :map
  end
end
