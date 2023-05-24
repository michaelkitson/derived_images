# frozen_string_literal: true

module DerivedImages
  class ManifestEntry
    attr_accessor :source, :target, :chain

    def initialize(source, target, chain)
      @source = source
      @target = target
      @chain = chain
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
  end
end
