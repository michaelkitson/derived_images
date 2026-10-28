# frozen_string_literal: true

require 'test_helper'

class WorkerTest < MockEnvironmentTestCase
  def setup
    super
    @cache = DerivedImages::Cache.new(nil)
    @queue = Thread::Queue.new
    @failed = Thread::Queue.new
    @worker = DerivedImages::Worker.new(@queue, @cache, failures: @failed)
  end

  attr_reader :failed, :queue, :worker

  test '#run with empty queue' do
    queue.close
    assert_nothing_raised do
      Timeout.timeout(0.1) { worker.run }
    end
  end

  test '#run with missing source file' do
    queue << DerivedImages::ManifestEntry.new('non-existent-source.png', 'target.png')
    queue.close
    assert_nothing_raised do
      Timeout.timeout(0.1) { worker.run }
    end
  end

  test '#run continues after an entry fails' do
    image_path = Pathname.new(DerivedImages.config.image_paths.first)
    image_path.join('corrupt.jpg').write('not an image')
    FileUtils.cp('test/fixtures/files/sample.jpg', image_path.join('sample.jpg'))
    corrupt = DerivedImages::ManifestEntry.new('corrupt.jpg', 'corrupt.png')
    queue << corrupt
    queue << DerivedImages::ManifestEntry.new('sample.jpg', 'sample.png')
    queue.close
    assert_nothing_raised do
      Timeout.timeout(5) { worker.run }
    end
    assert_predicate Pathname.new(DerivedImages.config.build_path).join('sample.png'), :file?
    assert_equal [corrupt], Array.new(failed.length) { failed.pop }
  end
end
