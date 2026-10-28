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

    # Builds every image in the manifest, then raises {BuildError} if any of them failed.
    def run_once
      @failures = Thread::Queue.new
      process_all
      queue.close
      @workers.list.each(&:join)
      raise_failures
    end

    private

    attr_reader :cache, :failures, :image_listener, :manifest, :manifest_listener, :queue, :workers

    def watch_manifest
      # Listen can only watch whole directories (recursively), so ignore changes to anything but the manifest itself.
      manifest_path = resolve_path(manifest.path)
      @manifest_listener = Listen.to(manifest.path.dirname) do |modified, added, removed|
        manifest_changed if (modified + added + removed).any? { resolve_path(_1) == manifest_path }
      end
      manifest_listener.start
    end

    def watch_images
      @image_listener = Listen.to(*DerivedImages.config.image_paths) do |modified, added, removed|
        images_changed(modified + added + removed)
      end
      image_listener.start
    end

    def manifest_changed
      DerivedImages.config.logger.debug('Reloading changed manifest')
      former_manifest = manifest
      @manifest = Manifest.new.tap(&:draw)
      _added, _changed, removed = manifest.diff_from(former_manifest)
      remove_targets(removed)
      process_all
    end

    def remove_targets(entries)
      entries.each do |entry|
        next unless entry.target_path.file?

        entry.target_path.delete
        DerivedImages.config.logger.info("Removed #{entry.target}")
      end
    end

    def images_changed(paths)
      paths.each do |path|
        manifest.produced_from(resolve_path(path)).each { enqueue(_1) }
      end
      prune_cache
    end

    # Resolves symlinks like `realpath`, but also works for paths that have been removed, by resolving the nearest
    # ancestor that still exists.
    def resolve_path(path)
      path = Pathname.new(path).expand_path
      path.realdirpath
    rescue Errno::ENOENT
      resolve_path(path.dirname).join(path.basename)
    end

    def process_all
      manifest.each_value { enqueue(_1) }
      prune_cache
    end

    def enqueue(entry)
      # Waiting workers stay counted until they wake and pop, so compare them against the backlog rather than zero.
      should_expand = queue.length >= queue.num_waiting && workers.list.length < DerivedImages.config.threads
      queue << entry
      Worker.start(workers, queue, failures: failures) if should_expand
    end

    def raise_failures
      targets = Array.new(failures.length) { failures.pop.target }
      raise BuildError, "Failed to build #{targets.sort.join(', ')}" if targets.any?
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
