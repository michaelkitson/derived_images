# frozen_string_literal: true

require 'test_helper'

class ManifestTest < MockEnvironmentTestCase
  def setup
    super
    @manifest = DerivedImages::Manifest.new(nil)
    manifest.draw do
      derive('a.png', from: 'c.png')
      derive('b.png', from: 'c.png')
      derive('1.png', from: '2.png')
    end
  end

  attr_reader :manifest

  test '#draw from a block' do
    assert_equal 3, manifest.count
  end

  test '#draw from a file' do
    Tempfile.create do |file|
      file.write("derive 'a.png', from: 'c.png'\n derive 'b.png', from: 'c.png'\n derive '1.png', from: '2.png'")
      file.rewind
      @manifest = DerivedImages::Manifest.new(file.path)
      manifest.draw
    end
    assert_equal 3, manifest.count
  end

  test '#produced_from' do
    entries = manifest.produced_from(Pathname.new(DerivedImages.config.image_paths.first).join('c.png').expand_path)
    assert_equal 2, entries.length
    assert_equal 'c.png', entries[0].source
    assert_equal 'c.png', entries[1].source
  end

  test '#diff_from' do
    new_manifest = DerivedImages::Manifest.new(nil)
    new_manifest.draw do
      resize('a.png', from: 'c.png', width: 1, height: 1) # Changed
      derive('b.png', from: 'c.png') # Constant
      # derive('1.png', from: '2.png') # Removed
      derive('3.png', from: '2.png') # Added
    end

    added, changed, removed = new_manifest.diff_from(manifest)
    assert_equal '3.png', added.sole.target
    assert_equal 'a.png', changed.sole.target
    assert_equal '1.png', removed.sole.target
  end
end
