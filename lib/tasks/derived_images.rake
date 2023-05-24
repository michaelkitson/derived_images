# frozen_string_literal: true

namespace :derived_images do
  desc 'install derived_images'
  task :install do
    system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path('../install/install.rb',
                                                                                  __dir__)}"
  end

  desc 'build assets from derived_images once'
  task :build do
    DerivedImages::Processor.new.run_once
  end
end

Rake::Task['assets:precompile'].enhance(['derived_images:build']) if Rake::Task.task_defined?('assets:precompile')
