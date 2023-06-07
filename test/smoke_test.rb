# frozen_string_literal: true

require 'test_helper'

class SmokeTest < MockEnvironmentTestCase
  def setup
    super
    @formats = %i[bmp gif jpg png jp2 webp avif heic jxl]
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

  test 'creates files with vips' do
    DerivedImages.config.processor = :vips
    processor.run_once
    check_presence
  end

  test 'creates files with imagemagick' do
    DerivedImages.config.processor = :mini_magick
    processor.run_once
    check_presence
  end

  test 'implicitly converts files with vips' do
    DerivedImages.config.processor = :vips
    processor.run_once
    check_magic_numbers
  end

  test 'implicitly converts files with imagemagick' do
    DerivedImages.config.processor = :mini_magick
    processor.run_once
    check_magic_numbers
  end

  def check_presence
    formats.each do |format|
      assert build_path.join("test.#{format}").file?
      assert_equal '100644', format('%o', build_path.join("test.#{format}").stat.mode)
    end
  end

  def check_magic_numbers
    assert_equal 'BM'.b, build_path.join('test.bmp').read(2), 'Outputs a bmp'
    assert_equal 'GIF89a'.b, build_path.join('test.gif').read(6), 'Outputs a gif'
    assert_equal "\xff\xd8\xff".b, build_path.join('test.jpg').read(3), 'Outputs a jpg'
    assert_equal "\x89PNG".b, build_path.join('test.png').read(4), 'Outputs a png'
    assert_equal 'RIFF', build_path.join('test.webp').read(4), 'Outputs a webp'
    assert_equal 'ftypavif', build_path.join('test.avif').read(12).last(8), 'Outputs an avif'
    assert_equal 'ftypheic', build_path.join('test.heic').read(12).last(8), 'Outputs an heic'
    assert_equal "\xff\x0a".b, build_path.join('test.jxl').read(2), 'Outputs a jpegxl'
    assert_equal "\0\0\0\x0cjP  \x0d\n\x87\n".b, build_path.join('test.jp2').read(12), 'Outputs a jpeg 2000'
  end
end
