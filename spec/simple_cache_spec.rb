# frozen_string_literal: true

RSpec.describe AnyCache::SimpleCache do
  let(:cache) { described_class.new }

  describe '#initialize' do
    it 'creates a new instance with default parameters' do
      expect(cache).to be_a(AnyCache::SimpleCache)
    end

    it 'allows customizing size and thread safety' do
      custom_cache = described_class.new(size: 100, thread_safe: false)
      expect(custom_cache.instance_variable_get(:@size)).to eq(100)
      expect(custom_cache.instance_variable_get(:@cache)).to be_a(Hash)
    end
  end

  describe '#exists?' do
    it 'returns true if key exists' do
      cache.add('key', 'value')
      expect(cache.exists?('key')).to be true
    end

    it 'returns false if key does not exist' do
      expect(cache.exists?('nonexistent')).to be false
    end
  end

  describe '#[]' do
    it 'returns the value for an existing key' do
      cache.add('key', 'value')
      expect(cache['key']).to eq('value')
    end

    it 'returns nil for a non-existent key' do
      expect(cache['nonexistent']).to be_nil
    end

    it 'returns nil and removes the key if the item has expired' do
      cache.add('key', 'value', ttl: 0)
      sleep(0.1)
      expect(cache['key']).to be_nil
      expect(cache.exists?('key')).to be false
    end
  end

  describe '#add' do
    it 'adds a new key-value pair' do
      cache.add('key', 'value')
      expect(cache['key']).to eq('value')
    end

    it 'adds a new key-value pair with TTL' do
      cache.add('key', 'value', ttl: 0.2)
      expect(cache['key']).to eq('value')
      sleep(0.3)
      expect(cache['key']).to be_nil
    end
  end

  describe '#[]=' do
    it 'sets a new key-value pair' do
      cache['key'] = 'value'
      expect(cache['key']).to eq('value')
    end
  end

  describe '#fetch' do
    it 'returns existing value if key exists' do
      cache.add('key', 'value')
      expect(cache.fetch('key')).to eq('value')
    end

    it 'calls the block and returns its value if key does not exist' do
      value = cache.fetch('key') { 'new_value' }
      expect(value).to eq('new_value')
      expect(cache['key']).to eq('new_value')
    end
  end

  describe '#fetch_values' do
    it 'returns existing values if keys exist' do
      cache.add('key1', 'value1')
      cache.add('key2', 'value2')
      expect(cache.fetch_values('key1', 'key2')).to eq(%w[value1 value2])
    end

    it 'calls the block and returns its value if key does not exist' do
      values = cache.fetch_values('key1', 'key2') { 'value' }
      expect(values).to eq(%w[value value])
      expect(cache['key1']).to eq('value')
      expect(cache['key2']).to eq('value')
    end
  end

  describe '#delete' do
    it 'removes the key-value pair' do
      cache.add('key', 'value')
      cache.delete('key')
      expect(cache.exists?('key')).to be false
    end
  end

  describe '#save_to and .load_from' do
    let(:file_path) { 'tmp/cache.dump' }

    after do
      File.delete(file_path) if File.exist?(file_path)
    end

    it 'saves and loads the cache' do
      cache.add('key', 'value')
      cache.save_to(file_path: file_path, compressed: false)

      loaded_cache = described_class.load_from(file_path: file_path, compressed: false)
      expect(loaded_cache['key']).to eq('value')
    end

    it 'saves and loads the cache with compression' do
      cache.add('key', 'value')
      cache.save_to(file_path: file_path, compressed: true)

      loaded_cache = described_class.load_from(file_path: file_path, compressed: true)
      expect(loaded_cache['key']).to eq('value')
    end
  end

  describe '#inspect' do
    it 'returns a string representation of the cache' do
      expect(cache.inspect).to match(/#<AnyCache::SimpleCache:0x\h+ 0\/1024 keys>/)
    end
  end

  describe 'eviction' do
    it 'evicts old keys when the cache exceeds its size limit' do
      cache = described_class.new(size: 2)
      cache.add('key1', 'value1')
      cache.add('key2', 'value2')
      cache.add('key3', 'value3')

      expect(cache.exists?('key1')).to be false
      expect(cache.exists?('key2')).to be true
      expect(cache.exists?('key3')).to be true
    end
  end
end
