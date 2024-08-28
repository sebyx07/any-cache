# frozen_string_literal: true

module AnyCache
  class AllKeysLru < BaseCache
    def initialize(size: 1024, thread_safe: true)
      @size = size
      @cache = {}
      @lru_list = []
      @mutex = thread_safe ? Mutex.new : nil
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

        @cache[key] = CacheItems::Used.new(value, nil, Time.now)
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

        @cache[key] = CacheItems::Used.new(value, ttl ? Time.now + ttl : nil, Time.now)
        @lru_list.push(key)
        value
      end
    end

    def fetch(key)
      value = self[key]
      return value if value

      return unless block_given?

      value = yield
      self[key] = value
      value
    end

    def delete(key)
      synchronize do
        @cache.delete(key)
        @lru_list.delete(key)
      end
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

    def synchronize
      return yield unless @mutex
      return yield if @mutex.owned?

      @mutex.synchronize { yield }
    end
  end
end