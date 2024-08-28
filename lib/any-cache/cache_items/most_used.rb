# frozen_string_literal: true

module AnyCache
  module CacheItems
    MostUsed = Struct.new(:value, :expires_at, :count) do
      def expired?
        return false unless expires_at
        expires_at < Time.now
      end
    end
  end
end
