# frozen_string_literal: true

require 'test_helper'

class ProcessorTest < MockEnvironmentTestCase
  def setup
    super
    File.open(DerivedImages.config.manifest_path, 'w') do |f|
      f.puts 'derive "out1.png", from: "source1.png"'
      f.puts 'derive "out2.png", from: "source2.png"'
    end
    @processor = DerivedImages::Processor.new
    @queue = @processor.send(:queue)
  end

  def teardown
    @processor.unwatch
    super
  end

  # The listeners run on background threads, so poll instead of sleeping a fixed time.
  def wait_until(timeout: 5)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until yield
      return if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.01
    end
  end

  test '#run_once' do
    @processor.run_once
    assert_equal 2, @queue.length, 'enqueues the jobs'
    assert @queue.closed?, 'closes the queue'
  end

  test '#run_once prunes the cache' do
    cache = DerivedImages::Cache.new
    path = Pathname.new(DerivedImages.config.cache_path).join('data')
    path.write('')
    cache_key = '0' * 64
    cache.take_and_store(cache_key, path)
    assert cache.exist?(cache_key)
    @processor.run_once
    assert_not cache.exist?(cache_key)
  end

  test '#watch' do
    @processor.watch
    wait_until { @queue.length == 2 }
    assert_equal 2, @queue.length, 'enqueues the jobs'
    assert_not @queue.closed?, 'leaves the queue open'
  end

  test '#watch when manifest updated' do
    @processor.watch
    wait_until { @queue.length == 2 }
    @queue.clear
    assert @queue.empty?

    File.open(DerivedImages.config.manifest_path, 'a', &:puts)
    wait_until { @queue.length == 2 }
    assert_equal 2, @queue.length, 'enqueues the jobs'
  end

  test '#watch when image updated' do
    @processor.watch
    wait_until { @queue.length == 2 }
    @queue.clear
    assert @queue.empty?

    image_path = Pathname.new(DerivedImages.config.image_paths.first).join('source1.png')
    File.open(image_path, 'w', &:puts)
    wait_until { @queue.length == 1 }
    assert_equal 1, @queue.length, 'enqueues the jobs'
  end
end
