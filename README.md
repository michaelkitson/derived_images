# DerivedImages
[![Gem Version](https://badge.fury.io/rb/derived_images.svg)](https://rubygems.org/gems/derived_images)

ActiveStorage's `variant` functionality is awesome, so why not have it for images in the Rails asset pipeline too?

Use DerivedImages to programmatically create image assets by applying transformations to other assets.
Resize images, lower quality to save bytes, rotate, crop, convert between formats, and anything else that the
[image_processing](https://rubygems.org/gems/image_processing) gem supports.

## Installation

Rails ≥ 7.0, Ruby ≥ 2.7

1. Run `./bin/bundle add derived_images`
2. Run `./bin/rails derived_images:install`
3. Add the gem for your image processor, if it isn't already in your Gemfile for ActiveStorage/ImageProcessing
    - Vips (the default): `./bin/bundle add ruby-vips`
    - ImageMagick: `./bin/bundle add mini_magick`, and set `config.derived_images.processor = :mini_magick`
4. Install Vips or ImageMagick (if not already installed for ActiveStorage/ImageProcessing)
    - MacOS: `brew install vips` or `brew install imagemagick`
    - Debian/Ubuntu: `apt install libvips42` or `apt install imagemagick`

## Usage

After installing, specify images to create in the config file at `config/derived_images.rb`.

```ruby
derive 'my_derived_image.webp', from: 'my_source_image.jpg'
resize 'thumbnail.png', from: 'original.png', width: 400, height: 300
derive 'fully_custom.jpg', from: 'original.jpg' do |pipeline|
  pipeline.saver(quality: 50).resize_to_fill(80, 80).rotate(180)
end
```

In development, DerivedImages watches this file and the source images, compiling new assets into `app/assets/builds` where the asset
pipeline can pick them up with the normal asset helpers.

```erb
<%= image_tag('thumbnail.png') %>
```

## Configuration

Set options on `config.derived_images` in `config/application.rb` or an environment file.

| Option          | Default                                                  | Description                                                    |
|-----------------|----------------------------------------------------------|----------------------------------------------------------------|
| `enabled`       | `true` in development and test                           | Build images when the Rails server starts                      |
| `watch`         | `true` in development                                    | Keep watching for changes after the initial build              |
| `build_path`    | `'app/assets/builds'`                                    | Where derived images are written                               |
| `cache_path`    | `'tmp/cache/derived_images'` in development, else `nil`  | Where built images are cached; `nil` disables the cache        |
| `image_paths`   | `['app/assets/images']`                                  | Directories to look in for source images                       |
| `manifest_path` | `'config/derived_images.rb'`                             | The file listing the images to derive                          |
| `processor`     | `:vips`                                                  | `:vips` or `:mini_magick`                                      |
| `threads`       | Number of processors (`Etc.nprocessors`)                 | Maximum number of worker threads                               |

`rails derived_images:build` builds all images once regardless of `enabled`, and runs automatically before
`assets:precompile`.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
