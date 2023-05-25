# frozen_string_literal: true

require 'test_helper'

class ManifestTest < ActiveSupport::TestCase
  def setup
    @manifest = DerivedImages::Manifest.new(nil)
    manifest.draw do
      derive('a.png', 'c.png')
      derive('b.png', 'c.png')
      derive('1.png', '2.png')
    end
  end

  attr_reader :manifest

  def test_draw_from_block
    assert_equal 3, manifest.count
  end

  def test_draw_from_file
    Tempfile.create do |file|
      file.write("derive 'a.png', 'c.png'\n derive 'b.png', 'c.png'\n derive '1.png', '2.png'")
      file.rewind
      @manifest = DerivedImages::Manifest.new(file.path)
      manifest.draw
    end
    assert_equal 3, manifest.count
  end

  def test_produced_from
    entries = manifest.produced_from(Pathname.new('app/assets/images/c.png').expand_path)
    assert_equal 2, entries.length
    assert_equal 'c.png', entries[0].source
    assert_equal 'c.png', entries[1].source
  end

  def test_resize
    manifest.draw { resize('a.png', 'b.png', 640, 480) }
    entry = manifest['a.png']
    assert_equal 'a.png', entry.target
    assert_equal 'b.png', entry.source
    assert_equal([:resize_to_limit, [640, 480]], entry.chain.options[:operations].sole)
  end

  def test_derive
    chain = nil
    manifest.draw { derive('a.png', 'b.png') { chain = _1 } }
    assert_kind_of(ImageProcessing::Chainable, chain)
  end
end
