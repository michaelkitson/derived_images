# frozen_string_literal: true

module DerivedImages
  # A helper class to test for library support for different image formats.
  class FormatSupport
    KNOWN_FORMATS = %w[bmp gif jpg png webp avif heic jp2 jxl].freeze

    def initialize(processor = DerivedImages.config.processor)
      @processor = processor
    end

    KNOWN_FORMATS.each do |format|
      define_method("#{format}?") { supports?(format) }
    end

    alias jpeg_2000? jp2?
    alias jpeg_xl? jxl?

    def supports?(format)
      if processor == :vips
        vips.include?(format)
      elsif processor == :mini_magick
        magick.include?(format)
      else
        raise "Unknown processor #{processor}"
      end
    end

    def self.table(processor)
      instance = new(processor)
      %w[BMP GIF JPEG PNG TIFF WebP].map { [_1, true] }.tap do |table|
        table << ['AVIF', instance.avif?]
        table << ['HEIC', instance.heic?]
        table << ['JPEG 2000', instance.jpeg_2000?]
        table << ['JPEG XL', instance.jepg_xl?]
      end
    end

    private

    attr_reader :processor

    def vips
      @vips ||= Vips.get_suffixes.map { _1.delete('.') }
    end

    def magick
      @magick ||= begin
        output, = MiniMagick::Shell.new.execute(%w[identify -list format])
        lines = output.partition("\n\n").first.lines[2..]
        lines.reject { _1.start_with?(' ' * 10) } # Remove continuation lines
             .map { _1.strip.split(/\s+/, 4) } # split out fields ("Format Module Mode Description")
             .select { |_format, _, mode, _| mode.start_with?('rw') } # Read and write supported
             .map { _1.first.delete('*').downcase }
      end
    end
  end
end
