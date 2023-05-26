# frozen_string_literal: true

require 'test_helper'

class MockEnvironmentTestCase < ActiveSupport::TestCase
  def setup
    build_dir = Dir.mktmpdir
    cache_dir = Dir.mktmpdir
    image_path = Dir.mktmpdir
    manifest_path = Tempfile.new.path
    @paths_to_remove = [build_dir, cache_dir, image_path, manifest_path]

    Rails.application.config.derived_images.update(
      build_path: build_dir,
      cache_path: cache_dir,
      enabled?: true,
      image_paths: [image_path],
      manifest_path: manifest_path,
      threads: 0,
      watch?: false
    )
    super
  end

  def teardown
    @paths_to_remove.each { FileUtils.rmtree(_1) }
    super
  end
end
