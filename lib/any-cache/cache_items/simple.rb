# frozen_string_literal: true

module AnyCache
  module CacheItems
    Simple = Struct.new(:value, :expires_at) do
      def expired?
        return false unless expires_at
        expires_at < Time.now
      end
    end
  end
end
