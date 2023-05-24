# frozen_string_literal: true

say 'Create derived_images.rb manifest'
copy_file "#{__dir__}/derived_images.rb", 'config/derived_images.rb'

say 'Compile into app/assets/builds'
empty_directory 'app/assets/builds'
keep_file 'app/assets/builds'

if (sprockets_manifest_path = Rails.root.join('app/assets/config/manifest.js')).exist?
  append_to_file sprockets_manifest_path, %(//= link_tree ../builds\n)
end
