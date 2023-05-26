# frozen_string_literal: true

module DerivedImages
  # A Worker represents a thread in a thread pool that completes image creation tasks.
  class Worker
    def initialize(queue)
      @queue = queue
      @cache = Cache.new
    end

    def run
      until queue.closed? && queue.empty?
        entry = queue.pop
        process(entry) if entry
      end
    end

    def self.start(thread_group, queue)
      thread_group.add(Thread.new { Worker.new(queue).run })
    end

    private

    attr_reader :cache, :queue

    def process(entry)
      cache_key = entry.cache_key
      if cache.exist?(cache_key)
        restore(entry, cache_key)
      else
        generate(entry, cache_key)
      end
    end

    def restore(entry, cache_key)
      return if entry.target_path.file? && cache.digest(cache_key) == entry.target_digest

      cache.copy(cache_key, entry.target_path)
      DerivedImages.config.logger.debug("Restored #{entry.target} from cache")
    end

    def generate(entry, cache_key)
      time = Benchmark.realtime do
        tempfile = entry.pipeline.loader(fail: true).call(entry.source_path.to_s)
        FileUtils.mv(tempfile.path, entry.target_path)
      end
      cache.store(cache_key, entry.target_path)
      DerivedImages.config.logger.debug("Created #{entry.target} from #{entry.source} in #{time.round(3)}s")
    end
  end
end
