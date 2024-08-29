# frozen_string_literal: true

require 'mutex_m'
require 'concurrent/map'
require 'zlib'

Dir.glob(File.join(__dir__, 'any-cache', '**', '*.rb')).sort.each do |file|
  require file
end

module AnyCache
  class Error < StandardError; end
  ALLOWED_TYPES = {
    simple: SimpleCache,
    lru: LRUCache,
    lfu: LFUCache,
  }

  def self.new(type, size: 1024, compressed: true, thread_safe: true, file_path: nil)
    unless ALLOWED_TYPES.key?(type)
      raise Error, "Invalid cache type: #{type}, allowed types are: #{ALLOWED_TYPES.keys.join(', ')}"
    end

    klass = ALLOWED_TYPES[type]
    if file_path && File.exist?(file_path)
      return klass.load_from(file_path: file_path, compressed: compressed)
    end

    klass.new(size: size, thread_safe: thread_safe)
  end
end
