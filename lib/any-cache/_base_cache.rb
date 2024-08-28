# frozen_string_literal: true

module AnyCache
  class BaseCache
    def self.load_from(file_path:, compressed: true)
      new.tap do |instance|
        if compressed
          cache = Marshal.load(Zlib::Inflate.inflate(File.read(file_path)))
        else
          cache = Marshal.load(File.read(file_path))
        end
        instance.instance_variable_set(:@cache, cache)
      end
    end

    def initialize(size: 1024, thread_safe: true)
      @size = size
      @cache = thread_safe ? Concurrent::Map.new : {}
    end

    def exists?(key)
      @cache.key?(key)
    end

    def [](key)
      @cache[key].then do |cache_item|
        next unless cache_item
        if cache_item.expired?
          @cache.delete(key)
          nil
        else
          cache_item.value
        end
      end
    end

    def add(key, value, ttl: nil)
      @cache[key] = CacheItems::Simple.new(value, ttl ? Time.now + ttl : nil)
      evict_old_keys
    end

    def []=(key, value)
      @cache[key] = CacheItems::Simple.new(value, nil)
      evict_old_keys
    end

    def fetch(key)
      val = self[key]
      return val if val
      return unless block_given?

      value = yield
      self[key] = value
      value
    end

    def fetch_values(*keys, &block)
      keys.map { |key| fetch(key, &block) }
    end

    def delete(key)
      @cache.delete(key)
    end

    def save_to(file_path:, compressed: true)
      if compressed
        File.write(file_path, Zlib::Deflate.deflate(Marshal.dump(@cache)))
      else
        File.write(file_path, Marshal.dump(@cache))
      end
    end

    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} #{@cache.size}/#{@size} keys>"
    end

    private
      def evict_old_keys
        @cache.delete(@cache.keys.first) if @cache.size > @size && @size&.positive?
      end
  end
end
