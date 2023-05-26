# frozen_string_literal: true

require 'test_helper'

class WorkerTest < ActiveSupport::TestCase
  def setup
    @cache = DerivedImages::Cache.new(enabled: false)
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
end
