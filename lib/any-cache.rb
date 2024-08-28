# frozen_string_literal: true

require 'mutex_m'
require 'concurrent/map'
require 'zlib'

Dir.glob(File.join(__dir__, 'any-cache', '**', '*.rb')).sort.each do |file|
  require file
end

module AnyCache
  class Error < StandardError; end
  # Your code goes here...
end
