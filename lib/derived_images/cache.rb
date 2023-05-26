# frozen_string_literal: true

module DerivedImages
  # Build cache for derived image files.
  class Cache
    include Enumerable

    # @param [Pathname, String] path The cache directory, which will be created if it does not exist.
    # @param [Boolean] enabled If disabled, the cache will ignore every call
    def initialize(path = 'tmp/cache/derived_images', enabled: DerivedImages.config.cache?)
      @path = Pathname.new(path)
      @enabled = enabled
    end

    # Copy a cached file out to another path.
    #
    # @param [String] key Cache key
    # @param [Pathname, String] path
    def copy(key, path)
      enabled? && FileUtils.copy(key_path(key), path)
    end

    # Check for the presence of a cached file.
    #
    # @param [String] key Cache key
    # @return [Boolean]
    def exist?(key)
      enabled? && key_path(key).file?
    end

    # Remove a cached file, if it exists.
    #
    # @param [String] key Cache key
    def remove(key)
      return unless enabled?

      key_path(key).delete if key_path(key).exist?
      maybe_clean_dir_for(key)
    end

    # Copy a file into the cache.
    #
    # @param [String] key Cache key
    # @param [Pathname, String] path
    def store(key, path)
      return unless enabled?

      mkdir_for(key)
      FileUtils.copy(path, key_path(key))
    end

    # Move (not copy) a file into the cache.
    #
    # @param [String] key Cache key
    # @param [Pathname, String] path
    def take_and_store(key, path)
      return unless enabled?

      mkdir_for(key)
      FileUtils.mv(path, key_path(key))
    end

    # Convert a cache key into a filesystem path of where it would be stored.
    #
    # @param [String] key Cache key
    # @return [Pathname]
    def key_path(key)
      path.join(key[0...2], key[2..])
    end

    # Iterates over cache keys.
    #
    # @yieldparam key [String] the cache key
    # @return [DerivedImages::Cache, Enumerator]
    def each
      return enum_for(:each) unless block_given?

      path.glob('*/*') { |path| yield path.to_s.last(65).delete('/') }
      self
    end

    private

    attr_reader :path

    # Create parent directories so that we can store a value at the given key.
    #
    # @param [String] key Cache key
    def mkdir_for(key)
      FileUtils.mkdir_p(key_path(key).dirname)
    end

    # Clean up any unnecessary parent directories above the given cache key.
    #
    # @param [String] key Cache key
    def maybe_clean_dir_for(key)
      dir = key_path(key).dirname
      dir.rmdir if dir.directory? && dir.empty?
    end

    def enabled?
      @enabled
    end
  end
end
