# frozen_string_literal: true

namespace :derived_images do
  desc 'install derived_images'
  task :install do
    system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path('../install/install.rb',
                                                                                  __dir__)}"
  end

  desc 'build assets from derived_images once'
  task build: :environment do
    DerivedImages::Processor.new.run_once
  end
end

task 'assets:precompile' => 'derived_images:build'
