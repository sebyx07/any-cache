# frozen_string_literal: true

module AnyCache
  class LRUCache < BaseCache
    def initialize(size: 1024, thread_safe: true)
      @size = size
      @cache = {}
      @lru_list = []
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
          update_lru(key)
          cache_item.value
        end
      end
    end

    def []=(key, value)
      synchronize do
        if @cache.key?(key)
          update_lru(key)
        elsif @cache.size >= @size
          evict_lru
        end

        @cache[key] = CacheItems::LastUsedAt.new(value, nil, Time.now)
        @lru_list.push(key)
        value
      end
    end

    def add(key, value, ttl: nil)
      synchronize do
        if @cache.key?(key)
          update_lru(key)
        elsif @cache.size >= @size
          evict_lru
        end

        @cache[key] = CacheItems::LastUsedAt.new(value, ttl ? Time.now + ttl : nil, Time.now)
        @lru_list.push(key)
        value
      end
    end

    def delete(key)
      synchronize do
        @cache.delete(key)
        @lru_list.delete(key)
      end
    end

    def keys
      synchronize { @cache.keys }
    end

    def clear
      synchronize { @cache.clear }
    end

    private
      def update_lru(key)
        @lru_list.delete(key)
        @lru_list.push(key)
        @cache[key].last_used_at = Time.now
      end

      def evict_lru
        lru_key = @lru_list.shift
        @cache.delete(lru_key)
      end

      def synchronize(&block)
        return yield unless @mutex
        return yield if @mutex.owned?

        @mutex.synchronize(&block)
      end
  end
end
