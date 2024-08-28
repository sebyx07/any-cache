RSpec.describe AnyCache::AllKeysLru do
  let(:cache_size) { 3 }
  let(:cache) { described_class.new(size: cache_size) }

  describe '#initialize' do
    it 'creates a cache with the specified size' do
      expect(cache.instance_variable_get(:@size)).to eq(cache_size)
    end

    it 'creates a thread-safe cache when specified' do
      thread_safe_cache = described_class.new(size: cache_size, thread_safe: true)
      expect(thread_safe_cache.instance_variable_get(:@mutex)).to be_a(Mutex)
    end

    it 'creates a thread-safe cache by default' do
      expect(cache.instance_variable_get(:@mutex)).to be_a(Mutex)
    end
  end

  describe '#[]' do
    it 'returns nil for non-existent keys' do
      expect(cache['non-existent']).to be_nil
    end

    it 'returns the value for existing keys' do
      cache['key'] = 'value'
      expect(cache['key']).to eq('value')
    end

    it 'updates the LRU order when accessing a key' do
      cache['key1'] = 'value1'
      cache['key2'] = 'value2'
      cache['key1']
      expect(cache.instance_variable_get(:@lru_list).last).to eq('key1')
    end
  end

  describe '#[]=' do
    it 'adds a new key-value pair to the cache' do
      cache['key'] = 'value'
      expect(cache['key']).to eq('value')
    end

    it 'updates an existing key' do
      cache['key'] = 'value1'
      cache['key'] = 'value2'
      expect(cache['key']).to eq('value2')
    end

    it 'evicts the least recently used item when cache is full' do
      cache['key1'] = 'value1'
      cache['key2'] = 'value2'
      cache['key3'] = 'value3'
      cache['key4'] = 'value4'
      expect(cache['key1']).to be_nil
      expect(cache['key4']).to eq('value4')
    end
  end

  describe '#add' do
    it 'adds a new key-value pair with TTL' do
      cache.add('key', 'value', ttl: 1)
      expect(cache['key']).to eq('value')
    end

    it 'expires items after TTL' do
      cache.add('key', 'value', ttl: 0.1)
      sleep(0.3)
      expect(cache['key']).to be_nil
    end
  end

  describe '#fetch' do
    it 'returns the value if the key exists' do
      cache['key'] = 'value'
      expect(cache.fetch('key')).to eq('value')
    end

    it 'executes the block and returns the value if the key does not exist' do
      value = cache.fetch('key') { 'new_value' }
      expect(value).to eq('new_value')
      expect(cache['key']).to eq('new_value')
    end
  end

  describe '#delete' do
    it 'removes the key-value pair from the cache' do
      cache['key'] = 'value'
      cache.delete('key')
      expect(cache['key']).to be_nil
    end

    it 'removes the key from the LRU list' do
      cache['key'] = 'value'
      cache.delete('key')
      expect(cache.instance_variable_get(:@lru_list)).not_to include('key')
    end
  end

  describe 'thread safety' do
    let(:thread_safe_cache) { described_class.new(size: cache_size, thread_safe: true) }

    it 'handles concurrent access without errors' do
      threads = 10.times.map do
        Thread.new do
          100.times do |i|
            thread_safe_cache["key#{i}"] = "value#{i}"
            thread_safe_cache["key#{i}"]
            thread_safe_cache.delete("key#{i}")
          end
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end
  end
end