# frozen_string_literal: true

module DerivedImages
  # The Processor manages a {Manifest}, watches the filesystem for changes, and manages a pool of {Worker} instances
  # which perform the image tasks.
  class Processor
    def initialize
      @cache = Cache.new
      @manifest = Manifest.new.tap(&:draw)
      @queue = Thread::Queue.new
      @workers = ThreadGroup.new
    end

    def watch
      watch_manifest
      watch_images
      process_all
    end

    def unwatch
      manifest_listener&.stop
      image_listener&.stop
    end

    def run_once
      process_all
      queue.close
      @workers.list.each(&:join)
    end

    private

    attr_reader :cache, :image_listener, :manifest, :manifest_listener, :queue, :workers

    def watch_manifest
      dir, file = manifest.path.split.map(&:to_s)
      @manifest_listener = Listen.to(dir, only: Regexp.new(file)) do
        DerivedImages.config.logger.debug('Reloading changed manifest')
        @manifest = Manifest.new.tap(&:draw)
        process_all
      end
      manifest_listener.start
    end

    def watch_images
      @image_listener = Listen.to(*DerivedImages.config.image_paths) do |modified, added, removed|
        (modified + added + removed).each do |path|
          source_path = Pathname.new(path).expand_path.realpath
          manifest.produced_from(source_path).each { enqueue(_1) }
        end
        prune_cache
      end
      image_listener.start
    end

    def process_all
      manifest.each_value { enqueue(_1) }
      prune_cache
    end

    def enqueue(entry)
      should_expand = queue.num_waiting.zero? && workers.list.length < DerivedImages.config.threads
      queue << entry
      Worker.start(workers, queue) if should_expand
    end

    def prune_cache
      expected_keys = manifest.filter_map { |_target, entry| entry.cache_key }
      (cache.to_a - expected_keys).each do |key|
        DerivedImages.config.logger.debug("Removing cached file at #{key}")
        cache.remove(key)
      end
    end
  end
end
