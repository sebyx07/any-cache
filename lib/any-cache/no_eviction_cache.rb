# frozen_string_literal: true

module AnyCache
  class NoEvictionCache < BaseCache
    def []=(key, value)
      return if @cache.size >= @size

      @cache[key] = value
    end
  end
end
