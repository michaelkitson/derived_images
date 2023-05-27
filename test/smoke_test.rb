# frozen_string_literal: true

require 'test_helper'

class SmokeTest < MockEnvironmentTestCase
  def setup
    super
    @formats = %i[bmp gif jpg png webp avif]
    File.open(DerivedImages.config.manifest_path, 'w') do |f|
      formats.each { f.puts "derive 'test.#{_1}', from: 'sample.jpg'" }
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

  attr_reader :build_path, :formats, :processor

  test 'creates files' do
    processor.run_once
    formats.each do |format|
      assert build_path.join("test.#{format}").file?
    end
  end

  test 'implicitly converts files' do
    processor.run_once
    assert_equal 'BM'.b, build_path.join('test.bmp').read(2), 'Outputs a bmp'
    assert_equal 'GIF89a'.b, build_path.join('test.gif').read(6), 'Outputs a gif'
    assert_equal "\xff\xd8\xff".b, build_path.join('test.jpg').read(3), 'Outputs a jpg'
    assert_equal "\x89PNG".b, build_path.join('test.png').read(4), 'Outputs a png'
    assert_equal 'RIFF', build_path.join('test.webp').read(4), 'Outputs a webp'
    assert_equal 'ftypavif', build_path.join('test.avif').read(12).last(8), 'Outputs an avif'
  end
end
