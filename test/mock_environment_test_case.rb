# frozen_string_literal: true

require 'test_helper'

class MockEnvironmentTestCase < ActiveSupport::TestCase
  def setup
    build_dir = Dir.mktmpdir
    cache_dir = Dir.mktmpdir
    image_path = Dir.mktmpdir
    config_dir = Dir.mktmpdir
    @paths_to_remove = [build_dir, cache_dir, image_path, config_dir]

    DerivedImages.config.update(
      build_path: build_dir,
      cache_path: cache_dir,
      enabled?: true,
      image_paths: [image_path],
      # logger: Logger.new($stdout),
      manifest_path: File.join(config_dir, 'derived_images.rb'),
      processor: :vips,
      threads: 0,
      watch?: false
    )
    super
    # Listen.logger = DerivedImages.config.logger
  end

  def teardown
    @paths_to_remove.each { FileUtils.rmtree(_1) }
    super
  end
end
