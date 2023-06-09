# DerivedImages
[![Gem Version](https://badge.fury.io/rb/derived_images.svg)](https://rubygems.org/gems/derived_images)

ActiveStorage's `variant` functionality is awesome, so why not have it for images in the Rails asset pipeline too?

Use DerivedImages to programmatically create image assets by applying transformations to other assets.
Resize images, lower quality to save bytes, rotate, crop, convert between formats, and anything else that the
[image_processing](https://rubygems.org/gems/image_processing) gem supports.

## Installation

1. Run `./bin/bundle add derived_images`
2. Run `./bin/rails derived_images:install`
3. Install Vips or ImageMagick (if not already installed for ActiveStorage/ImageProcessing)
    - MacOS: `brew install vips` or `brew install imagemagick`
    - Debian/Ubuntu: `apt install libvips42` or `apt install imagemagick`

## Usage

After installing, specify images to create in the config file at `config/derived_images.rb`.

```ruby
derive 'my_derived_image.webp', from: 'my_source_image.jpg'
resize 'tiny.png', from: 'original.png', width: 400, height: 300
derive 'fully_custom.jpg', from: 'original.jpg' do |pipeline|
  pipeline.saver(quality: 50).resize_to_fill(80, 80).rotate(180)
end
```

DerivedImages watches this file and the source images, compiling new assets into `app/assets/builds` where the asset
pipeline can pick them up with the normal asset helpers.

```erbruby
<%= image_tag('tiny.png') %>
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
