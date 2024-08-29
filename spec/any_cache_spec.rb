# frozen_string_literal: true

RSpec.describe AnyCache do
  it 'has a version number' do
    expect(AnyCache::VERSION).not_to be nil
  end

  describe '.new' do
    context 'with valid cache types' do
      AnyCache::ALLOWED_TYPES.each do |type, klass|
        it "creates a new #{type} cache" do
          cache = described_class.new(type)
          expect(cache).to be_a(klass)
        end

        it "creates a new #{type} cache with custom options" do
          cache = described_class.new(type, compressed: false, thread_safe: false)
          expect(cache).to be_a(klass)
          expect(cache.instance_variable_get(:@mutex)).to be_nil
        end
      end
    end

    context 'with invalid cache type' do
      it 'raises an error' do
        expect { described_class.new(:invalid_type) }.to raise_error(AnyCache::Error, /Invalid cache type/)
      end
    end

    context 'with existing file path' do
      let(:file_path) { 'tmp/test_cache.dump' }
      let(:cache_data) { { 'key' => 'value' } }

      def prepare_data(type)
        AnyCache::ALLOWED_TYPES[type].new.tap do |cache|
          cache.add('key', 'value')
          cache.save_to(file_path: file_path)
        end
      end

      after do
        File.delete(file_path) if File.exist?(file_path)
      end

      AnyCache::ALLOWED_TYPES.each do |type, klass|
        it "loads #{type} cache from file" do
          prepare_data(type)
          cache = described_class.new(type, file_path: file_path)
          expect(cache).to be_a(klass)
          expect(cache['key']).to eq('value')
        end
      end
    end
  end

  describe 'thread safety' do
    AnyCache::ALLOWED_TYPES.each do |type, _|
      context "with #{type} cache" do
        let(:cache) { described_class.new(type, thread_safe: true) }

        it 'handles concurrent access without errors' do
          threads = 10.times.map do
            Thread.new do
              100.times do |i|
                cache.add("key#{i}", "value#{i}")
                cache["key#{i}"]
                cache.delete("key#{i}")
              end
            end
          end

          expect { threads.each(&:join) }.not_to raise_error
        end
      end
    end
  end

  describe 'compression' do
    AnyCache::ALLOWED_TYPES.each do |type, _|
      context "with #{type} cache" do
        let(:cache) { described_class.new(type, compressed: true) }
        let(:file_path) { "tmp/#{type}_cache.dump" }

        after do
          File.delete(file_path) if File.exist?(file_path)
        end

        it 'saves and loads compressed cache' do
          cache.add('key', 'value')
          cache.save_to(file_path: file_path)

          loaded_cache = described_class.new(type, file_path: file_path)
          expect(loaded_cache['key']).to eq('value')

          file_content = File.read(file_path)
          expect { Zlib::Inflate.inflate(file_content) }.not_to raise_error
        end
      end
    end
  end
end
