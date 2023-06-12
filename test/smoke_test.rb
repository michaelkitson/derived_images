# frozen_string_literal: true

require 'test_helper'

class SmokeTest < MockEnvironmentTestCase
  def setup
    super
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
    setup_processor(:vips)
    processor.run_once
    check_presence
  end

  test 'creates files with imagemagick' do
    setup_processor(:mini_magick)
    processor.run_once
    check_presence
  end

  test 'implicitly converts files with vips' do
    setup_processor(:vips)
    processor.run_once
    check_magic_numbers
  end

  test 'implicitly converts files with imagemagick' do
    setup_processor(:mini_magick)
    processor.run_once
    check_magic_numbers
  end

  def check_presence
    formats.each do |format|
      assert build_path.join("test.#{format}").file?, "creates a #{format}"
      assert_equal '100644', format('%o', build_path.join("test.#{format}").stat.mode), "#{format} has the correct mode"
    end
  end

  MAGIC = {
    bmp: 'BM',
    gif: 'GIF89a',
    jpg: "\xff\xd8\xff".b,
    png: "\x89PNG".b,
    webp: 'RIFF',
    avif: "\x00\x00\x00\x1cftypavif".b,
    heic: "\x00\x00\x00\x1cftypheic".b,
    jxl: "\xff\x0a".b,
    jp2: "\0\0\0\x0cjP  \x0d\n\x87\n".b
  }.freeze

  def check_magic_numbers
    MAGIC.each do |format, magic_string|
      assert_equal magic_string, build_path.join("test.#{format}").read(magic_string.bytesize), "#{format} has the correct magic string"
    end
  end

  def setup_processor(processor)
    DerivedImages.config.processor = processor
    format_support = DerivedImages::FormatSupport.new(processor)
    @formats = DerivedImages::FormatSupport::KNOWN_FORMATS.filter { format_support.supports?(_1) }
    File.open(DerivedImages.config.manifest_path, 'w') do |f|
      formats.each { f.puts "derive 'test.#{_1}', from: 'sample.jpg'" }
    end
    @processor = DerivedImages::Processor.new
  end
end
