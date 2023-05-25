# frozen_string_literal: true

module DerivedImages
  # The Processor manages a {Manifest}, watches the filesystem for changes, and manages a pool of {Worker} instances
  # which perform the image tasks.
  class Processor
    def initialize
      @manifest = Manifest.new
      @queue = Thread::Queue.new
      @workers = ThreadGroup.new
      manifest.draw
    end

    def watch
      watch_manifest
      watch_images
      process_all
    end

    def run_once
      process_all
      @queue.close
    end

    private

    attr_reader :image_listener, :manifest, :manifest_listener

    def watch_manifest
      @manifest_listener = Listen.to(manifest.path.dirname, only: Regexp.new(manifest.path.basename.to_s)) do
        manifest.draw
        process_all
      end
      manifest_listener.start
    end

    def watch_images
      @image_listener = Listen.to(*DerivedImages.config.image_paths) do |modified, added, removed|
        (modified + added).each { handle_update(Pathname.new(_1).expand_path) }
        removed.each { handle_removal(Pathname.new(_1).expand_path) }
      end
      image_listener.start
    end

    def handle_update(source_path)
      manifest.produced_from(source_path).each { enqueue(_1) }
    end

    def handle_removal(source_path)
      return unless manifest.produced_from(source_path).empty?

      raise "Invalid config (file not found) #{source_path}"
    end

    def process_all
      manifest.each_value { enqueue(_1) }
    end

    def enqueue(entry)
      should_expand = @queue.num_waiting.zero? && @workers.list.length < DerivedImages.config.threads
      @queue << entry
      Worker.start(@workers, @queue) if should_expand
    end
  end
end
