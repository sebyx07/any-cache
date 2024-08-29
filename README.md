# AnyCache 🚀

__THIS IS NOT A DATABASE!__

AnyCache is a versatile in-memory caching library for Ruby, supporting various cache eviction strategies. It's designed for applications needing efficient, customizable caching mechanisms.

## Features 🌟

- Multiple cache types: Simple, LRU (Least Recently Used), LFU (Least Frequently Used)
- Thread-safe operations (optional)
- Compression support
- Persist caches to disk and reload them
- Easy to use API

## Installation 💎

Add this line to your application's Gemfile:

```ruby
gem 'any-cache'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install any-cache
```

## Usage 🔧

### Basic Usage

```ruby
require 'any-cache'

# Create a new LRU cache
# 1024 is the default
# Thread safety is enabled by default, but disabling can improve throughput
cache = AnyCache.new(:lru, size: 1024, thread_safe: false)

# Add items to the cache
cache.add('key1', 'value1')
cache['key2'] = 'value2'
cache.add('key3', 'value3', ttl: 30)  # Expires after 30 seconds

# Retrieve items
puts cache['key1']  # Output: value1
puts cache.fetch('key3')  # Output: value3

puts cache.fetch('key4') { 'default_value' }  # Output: default_value
puts cache.fetch_values('key1', 'key5')  { 'default_value' } # Output: ['value1', 'default_value']

# Delete items
cache.delete('key2')

sleep 60
puts cache['key3']  # Output: nil
```

### Cache Types

AnyCache supports three types of caches:

- `:simple` - Simple cache eviction FIFO (First In First Out) strategy
- `:lru` - Least Recently Used eviction strategy
- `:lfu` - Least Frequently Used eviction strategy

```ruby
simple_cache = AnyCache.new(:simple)
lru_cache = AnyCache.new(:lru)
lfu_cache = AnyCache.new(:lfu)
```

### Thread Safety ⚠️

When using the cache as a class attribute, it's recommended to use thread-safe mode:

```ruby
class MyClass
  class << self
    def cache
      @cache ||= AnyCache.new(:lru, thread_safe: true)
    end
  end
end
```

For local variables or when thread safety is not a concern, you can disable it for better performance:

```ruby
local_cache = AnyCache.new(:lru, thread_safe: false)
```

### Compression and Persistence 💾

AnyCache supports compressing cached data and persisting it to disk:

```ruby
# Create a compressed cache
compressed_cache = AnyCache.new(:lru, compressed: true)

# Save cache to disk
compressed_cache.save_to(file_path: 'my_cache.dump')

# Load cache from disk
loaded_cache = AnyCache.new(:lru, file_path: 'my_cache.dump')
```

### Advanced Usage

```ruby
cache = AnyCache.new(:lru, size: 100)

# Add an item with a TTL (Time To Live)
cache.add('key', 'value', ttl: 60)  # Expires after 60 seconds

# Fetch or compute a value
value = cache.fetch('key') { 'computed_value' }

# Get all keys
keys = cache.keys

# Clear the cache
cache.clear
```

## Development 🛠️

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing 🤝

Bug reports and pull requests are welcome on GitHub at https://github.com/sebyx07/any_cache. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## License 📄

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct 🤓

Everyone interacting in the AnyCache project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).