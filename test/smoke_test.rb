# frozen_string_literal: true

require 'test_helper'

class SmokeTest < MockEnvironmentTestCase
  def setup
    super
    File.open(DerivedImages.config.manifest_path, 'w') do |f|
      %i[jpg png webp].each { f.puts "derive 'test.#{_1}', from: 'sample.jpg'" }
    end
    @processor = DerivedImages::Processor.new
    @build_path = Pathname.new(DerivedImages.config.build_path)
    FileUtils.cp('test/fixtures/files/sample.jpg', DerivedImages.config.image_paths.first)
    DerivedImages.config.threads = 1
  end

  def teardown
    processor.unwatch
    super
  end

  attr_reader :build_path, :processor

  test 'creates files' do
    processor.run_once
    assert build_path.join('test.jpg').file?
    assert build_path.join('test.png').file?
    assert build_path.join('test.webp').file?
  end

  test 'implicitly converts files' do
    processor.run_once
    assert_equal "\xff\xd8\xff".b, build_path.join('test.jpg').read(3), 'Outputs a jpg'
    assert_equal "\x89PNG".b, build_path.join('test.png').read(4), 'Outputs a png'
    assert_equal 'RIFF', build_path.join('test.webp').read(4), 'Outputs a webp'
  end
end
