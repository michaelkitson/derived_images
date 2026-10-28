# frozen_string_literal: true

require 'test_helper'

class CacheTest < MockEnvironmentTestCase
  def setup
    super
    @cache = DerivedImages::Cache.new
  end

  test 'it correctly builds key paths' do
    assert_equal '/tmp/so/mekey', DerivedImages::Cache.new('/tmp').key_path('somekey').to_s
  end

  test '#exist?' do
    dir.join('so').mkdir
    refute cache.exist?('somekey')
    dir.join('so/mekey').write('')
    assert cache.exist?('somekey')
  end

  test '#remove' do
    dir.join('so').mkdir
    dir.join('so/mekey').write('')
    cache.remove('somekey')
    refute dir.join('so/mekey').file?
    refute dir.join('so').exist?
    assert_nothing_raised { cache.remove('somekey') }
  end

  test '#copy' do
    target_path = dir.join('sample')
    dir.join('so').mkdir
    dir.join('so/mekey').write('test content')
    refute target_path.file?
    cache.copy('somekey', target_path)
    assert target_path.file?
    assert_equal 'test content', target_path.read
  end

  test '#store' do
    source_path = dir.join('sample')
    source_path.write('test content')
    target_path = dir.join('so/mekey')
    refute target_path.file?
    cache.store('somekey', source_path)
    assert target_path.file?
    assert_equal 'test content', target_path.read
  end

  test '#copy replaces an existing file without leaving temporary files' do
    target_path = dir.join('sample')
    target_path.write('old content')
    dir.join('so').mkdir
    dir.join('so/mekey').write('new content')
    cache.copy('somekey', target_path)
    assert_equal 'new content', target_path.read
    assert_equal %w[sample so so/mekey], dir_entries
  end

  test '#store does not leave temporary files' do
    source_path = dir.join('sample')
    source_path.write('test content')
    cache.store('somekey', source_path)
    assert_equal %w[sample so so/mekey], dir_entries
  end

  test '#store removes its temporary file if it fails' do
    source_path = dir.join('sample')
    source_path.write('test content')
    dir.join('so/mekey').mkpath
    dir.join('so/mekey/blocker').write('')
    assert_raises(SystemCallError) { cache.store('somekey', source_path) }
    assert_equal %w[sample so so/mekey so/mekey/blocker], dir_entries
  end

  test '#take_and_store' do
    source_path = dir.join('sample')
    source_path.write('test content')
    target_path = dir.join('so/mekey')
    refute target_path.file?
    cache.take_and_store('somekey', source_path)
    assert target_path.file?
    assert_equal 'test content', target_path.read
    refute source_path.file?
  end

  test 'enumerable' do
    assert_kind_of Enumerator, cache.each, '#each with no block returns an Enumerator'
    assert_equal(cache, cache.each { _1 }, '#each with a block returns self')
    assert_equal 0, cache.count
    path = dir.join('sample').tap { _1.write('test') }
    cache_key = '0' * 64
    cache.take_and_store(cache_key, path)
    assert_equal 1, cache.count
    assert_equal cache_key, cache.min
  end

  test 'enumerable when disabled' do
    cache = DerivedImages::Cache.new(nil)
    assert_kind_of Enumerator, cache.each, '#each with no block returns an Enumerator'
    assert_equal(cache, cache.each { _1 }, '#each with a block returns self')
    assert_equal 0, cache.count
    path = dir.join('sample').tap { _1.write('test') }
    cache_key = '0' * 64
    cache.take_and_store(cache_key, path)
    assert_equal 0, cache.count
  end

  attr_reader :cache

  def dir
    Pathname.new(DerivedImages.config.cache_path)
  end

  # All paths under the cache directory, including dotfiles.
  def dir_entries
    Dir.glob('**/*', File::FNM_DOTMATCH, base: dir).reject { File.basename(_1) == '.' }.sort
  end
end
