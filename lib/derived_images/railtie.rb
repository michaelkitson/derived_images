# frozen_string_literal: true

module DerivedImages
  class Railtie < ::Rails::Railtie
    config.derived_images = ActiveSupport::OrderedOptions.new.update(
      build_path: 'app/assets/builds',
      enabled?: Rails.env.development? || Rails.env.test?,
      image_paths: ['app/assets/images'],
      manifest_path: 'config/derived_images.rb',
      processor: :vips,
      threads: 5,
      watch?: Rails.env.development?
    )

    initializer 'derived_images' do |app|
      derived_images = app.config.derived_images
      derived_images.logger = Rails.logger.tagged('derived_images')
    end

    rake_tasks do
      load 'tasks/derived_images.rake'
    end

    server do |app|
      derived_images = app.config.derived_images
      next unless derived_images.enabled?

      processor = DerivedImages::Processor.new
      if derived_images.watch?
        processor.watch
      else
        processor.run_once
      end
    end
  end
end
