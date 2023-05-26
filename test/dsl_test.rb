# frozen_string_literal: true

require 'test_helper'

class DslTest < ActiveSupport::TestCase
  class FakeManifest < Hash
    include DerivedImages::Dsl

    def add_entry(entry)
      self[entry.target] = entry
    end
  end

  def setup
    @manifest = FakeManifest.new
  end

  attr_reader :manifest

  test 'resize' do
    manifest.resize('target.webp', from: 'source.png', width: 640, height: 480)

    entry = manifest.values.first
    assert_equal 'target.webp', entry.target
    assert_equal 'source.png', entry.source
    assert_equal [:resize_to_limit, [640, 480]], entry.pipeline.options[:operations].sole
  end

  test 'derive' do
    manifest.derive('target.webp', from: 'source.png') do |pipeline|
      assert_kind_of(ImageProcessing::Chainable, pipeline)
      pipeline
    end

    entry = manifest.values.first
    assert_equal 'target.webp', entry.target
    assert_equal 'source.png', entry.source
  end
end
