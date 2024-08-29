# frozen_string_literal: true

module AnyCache
  class LFUCache < BaseCache
    def initialize(size: 1024, thread_safe: true)
      @size = size
      @cache = {}
      @mutex = thread_safe ? Mutex.new : nil
    end

    def exists?(key)
      synchronize { @cache.key?(key) }
    end

    def [](key)
      synchronize do
        cache_item = @cache[key]
        return unless cache_item

        if cache_item.expired?
          delete(key)
          nil
        else
          increment_frequency(key)
          cache_item.value
        end
      end
    end

    def []=(key, value)
      synchronize do
        if @cache.key?(key)
          increment_frequency(key)
          @cache[key].value = value
        elsif @cache.size >= @size
          evict_lfu
        end

        @cache[key] ||= CacheItems::MostUsed.new(value, nil, 0)
        value
      end
    end

    def add(key, value, ttl: nil)
      synchronize do
        if @cache.key?(key)
          increment_frequency(key)
          @cache[key].value = value
          @cache[key].expires_at = ttl ? Time.now + ttl : nil
        elsif @cache.size >= @size
          evict_lfu
        end

        @cache[key] ||= CacheItems::MostUsed.new(value, ttl ? Time.now + ttl : nil, 0)
        value
      end
    end

    def delete(key)
      synchronize do
        @cache.delete(key)
      end
    end

    def keys
      synchronize { @cache.keys }
    end

    def clear
      synchronize { @cache.clear }
    end

    private
      def increment_frequency(key)
        @cache[key].count += 1
      end

      def evict_lfu
        min_frequency = @cache.values.map(&:count).min
        lfu_keys = @cache.select { |_, v| v.count == min_frequency }.keys
        lfu_key = lfu_keys.first
        delete(lfu_key)
      end

      def synchronize(&block)
        return yield unless @mutex
        return yield if @mutex.owned?

        @mutex.synchronize(&block)
      end
  end
end
