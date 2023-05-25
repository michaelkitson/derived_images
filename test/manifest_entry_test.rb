# frozen_string_literal: true

require 'test_helper'

class ManifestEntryTest < ActiveSupport::TestCase
  def setup
    @files = [sample_file('test1'), sample_file('test2'), sample_file('test1')]
    @former_image_paths = DerivedImages.config.image_paths
    DerivedImages.config.image_paths = [File.dirname(@files[0].path)]
    @entries = @files.map do |file|
      pipeline = DerivedImages::ManifestEntry.empty_pipeline
      DerivedImages::ManifestEntry.new(File.basename(file.path), nil, pipeline)
    end
  end

  def teardown
    @files.each do |file|
      file.close
      file.unlink
    end
    DerivedImages.config.image_paths = @former_image_paths
  end

  def test_source_path
    assert_equal @files[0].path, @entries[0].source_path.to_s
  end

  def test_cache_key
    assert_equal '7db8b759e7a1b2d481f409b1c8f71509ffcf3a0ffbeb3f420938fd0f3263a42b', @entries[0].cache_key
    assert_not_equal @entries[0].cache_key, @entries[1].cache_key
    assert_equal @entries[0].cache_key, @entries[2].cache_key
    @entries[2].pipeline = @entries[2].pipeline.resize_to_limit(1, 1)
    assert_not_equal @entries[0].cache_key, @entries[2].cache_key
  end

  def sample_file(content)
    Tempfile.new.tap do |file|
      file.write(content)
      file.rewind
    end
  end
end
