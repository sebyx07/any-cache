# frozen_string_literal: true

require_relative 'lib/any-cache/version'

Gem::Specification.new do |spec|
  spec.name = 'any-cache'
  spec.version = AnyCache::VERSION
  spec.authors = ['sebi']
  spec.email = ['gore.sebyx@yahoo.com']

  spec.summary = 'Versatile in-memory caching library for Ruby with multiple eviction strategies.'
  spec.description = <<-DESC
    AnyCache is a flexible in-memory caching library for Ruby that supports various cache eviction strategies
    such as LRU (Least Recently Used), LFU (Least Frequently Used), and simple caching. It provides features#{' '}
    like thread-safety, optional compression, and the ability to persist caches to disk and reload them.#{' '}
    This library is designed for applications needing efficient, customizable caching mechanisms.
  DESC
  spec.homepage = 'https://github.com/sebyx07/any-cache'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'concurrent-ruby', '~> 1.3'
end
