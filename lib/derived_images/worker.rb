# frozen_string_literal: true

module DerivedImages
  # A Worker represents a thread in a thread pool that completes image creation tasks.
  class Worker
    def initialize(queue)
      @queue = queue
    end

    def work
      until @queue.closed? && @queue.empty?
        entry = @queue.pop
        process(entry) if entry
      end
    end

    def self.start(thread_group, queue)
      thread_group.add(Thread.new { Worker.new(queue).work })
    end

    private

    def process(entry)
      time = Benchmark.realtime do
        entry.chain.loader(fail: true).call(entry.source_path.to_s, destination: entry.target_path.to_s)
      end
      DerivedImages.config.logger.debug("Created #{entry.target} from #{entry.source} in #{time.round(3)}s")
    end
  end
end
