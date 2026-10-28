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
    assert_equal 2, @queue.length, 'enqueues the jobs'
    assert_not @queue.closed?, 'leaves the queue open'
  end

  test '#watch when manifest updated' do
    File.open(DerivedImages.config.manifest_path, 'a') { _1.puts 'derive "out3.png", from: "source3.png"' }
    @processor.send(:manifest_changed)
    assert_equal 3, @queue.length, 'reloads the manifest and enqueues the jobs'
  end

  test '#watch when image updated' do
    image_path = Pathname.new(DerivedImages.config.image_paths.first).join('source1.png')
    File.open(image_path, 'w', &:puts)
    @processor.send(:images_changed, [image_path.to_s])
    assert_equal ['out1.png'], queued_targets
  end

  test '#watch when image removed' do
    image_path = Pathname.new(DerivedImages.config.image_paths.first).join('source1.png')
    @processor.send(:images_changed, [image_path.to_s])
    assert_equal ['out1.png'], queued_targets
  end

  test '#watch when directory containing image removed' do
    File.open(DerivedImages.config.manifest_path, 'a') { _1.puts 'derive "out3.png", from: "removed/source3.png"' }
    @processor = DerivedImages::Processor.new
    @queue = @processor.send(:queue)
    image_path = Pathname.new(DerivedImages.config.image_paths.first).join('removed', 'source3.png')
    @processor.send(:images_changed, [image_path.to_s])
    assert_equal ['out3.png'], queued_targets
  end

  private

  def queued_targets
    Array.new(@queue.length) { @queue.pop(true).target }
  end
end
