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
    count = 0
    manifest.each { count += 1 }
    assert_equal 3, count
  end

  def test_draw_from_file
    Tempfile.create do |file|
      file.write("derive 'a.png', 'c.png'\n derive 'b.png', 'c.png'\n derive '1.png', '2.png'")
      file.rewind
      @manifest = DerivedImages::Manifest.new(file.path)
      manifest.draw
    end
    count = 0
    manifest.each { count += 1 }
    assert_equal 3, count
  end

  def test_produced_from
    assert_equal 2, manifest.produced_from(Pathname.new('app/assets/images/c.png').expand_path).length
  end

  def test_resize
    manifest.draw { resize('a.png', 'b.png', 640, 480) }
    entry = manifest.produced_from(Pathname.new('app/assets/images/b.png').expand_path).sole
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
