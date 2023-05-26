# frozen_string_literal: true

require 'test_helper'

class WorkerTest < ActiveSupport::TestCase
  def setup
    @cache = DerivedImages::Cache.new(nil)
    @queue = Thread::Queue.new
    @worker = DerivedImages::Worker.new(@queue, @cache)
  end

  attr_reader :queue, :worker

  test '#run with empty queue' do
    queue.close
    assert_nothing_raised do
      Timeout.timeout(0.1) { worker.run }
    end
  end

  test '#run with missing source file' do
    queue << DerivedImages::ManifestEntry.new('non-existent-source.png', 'target.png',
                                              DerivedImages::ManifestEntry.empty_pipeline)
    queue.close
    assert_nothing_raised do
      Timeout.timeout(0.1) { worker.run }
    end
  end
end
