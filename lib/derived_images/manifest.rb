# frozen_string_literal: true

module DerivedImages
  # The Manifest creates and holds a list of {ManifestEntry} instances, describing every derived image to create.
  class Manifest
    include Dsl

    def initialize(path = Rails.root.join(DerivedImages.config.manifest_path))
      @path = path
      @entry_map = {}
    end

    def draw(&block)
      @entry_map.clear
      if block
        instance_eval(&block)
      else
        instance_eval(File.read(path), path.to_s)
      end
    end

    def add_entry(entry)
      entry_map[entry.target] = entry
    end

    delegate :[], :count, :each, :each_value, :filter_map, :key?, :length, to: :entry_map

    def produced_from(source_path)
      source_names = []
      DerivedImages.config.image_paths.each do |path|
        dir = Pathname.new(path).expand_path.realpath
        contains_source_file = source_path.ascend.any? { _1 == dir }
        source_names << source_path.relative_path_from(dir).to_s if contains_source_file
      end
      entry_map.filter_map { |_target, entry| source_names.include?(entry.source) ? entry : nil }
    end

    attr_reader :path

    def diff_from(former_manifest)
      changed = []
      removed = []
      former_manifest.each do |target, entry|
        if key?(target)
          changed << entry if entry_map[target] != entry
        else
          removed << entry
        end
      end
      added = entry_map.filter_map { |target, entry| former_manifest.key?(target) ? nil : entry }
      [added, changed, removed]
    end

    private

    attr_reader :entry_map
  end
end
