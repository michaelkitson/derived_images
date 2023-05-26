# frozen_string_literal: true

require 'test_helper'

class ManifestEntryTest < ActiveSupport::TestCase
  def setup
    @files = [sample_file('test1'), sample_file('test2'), sample_file('test1')]
    @former_image_paths = DerivedImages.config.image_paths
    DerivedImages.config.image_paths = [File.dirname(@files[0].path)]
    @entries = @files.map do |file|
      DerivedImages::ManifestEntry.new(File.basename(file.path), 'target')
    end
  end

  def teardown
    @files.each do |file|
      file.close
      file.unlink
    end
    DerivedImages.config.image_paths = @former_image_paths
  end

  test '#==' do
    assert_equal @entries[0], @entries[0]
    assert_not_equal @entries[0], @entries[1]
    duplicated = @entries[0].dup
    duplicated.pipeline = DerivedImages::ManifestEntry.empty_pipeline
    assert_equal @entries[0], duplicated
  end

  test '#source_path' do
    assert_equal @files[0].path, @entries[0].source_path.to_s
  end

  test '#cache_key' do
    assert_equal 'd98176764f9aadf95294b4fe84158e61586dd12c67f580d3651ae592d5da1c3a', @entries[0].cache_key
    assert_not_equal @entries[0].cache_key, @entries[1].cache_key
    assert_equal @entries[0].cache_key, @entries[2].cache_key
    @entries[2].pipeline = @entries[2].pipeline.resize_to_limit(1, 1)
    assert_not_equal @entries[0].cache_key, @entries[2].cache_key
  end

  test '#cache_key manually constructed' do
    source = Digest::SHA256.hexdigest('test1')
    expected = Digest::SHA256.hexdigest({ source: source, pipeline: empty_pipeline_options }.to_json)
    assert_equal expected, @entries[0].cache_key
  end

  private

  def sample_file(content)
    Tempfile.new.tap do |file|
      file.write(content)
      file.rewind
    end
  end

  def empty_pipeline_options
    { source: nil, loader: {}, saver: {}, format: nil, operations: [], processor: 'ImageProcessing::Vips::Processor' }
  end
end
