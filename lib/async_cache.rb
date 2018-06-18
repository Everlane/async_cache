require 'sourcify'

module AsyncCache
  DEFAULT_OPTIONS = {
    # How long Sidekiq Enterprise should hold a uniqueness lock. The default
    # is 10 minutes.
    uniqueness_timeout: 600,
  }

  def self.options
    @options ||= DEFAULT_OPTIONS.dup
  end
  def self.options=(options)
    @options = options
  end

  def self.backend
    @backend ||= Rails.cache
  end
  def self.backend=(backend)
    @backend = backend
  end

  def self.logger
    @logger ||= Rails.logger
  end
  def self.logger=(logger)
    @logger = logger
  end
end

require 'async_cache/version'
require 'async_cache/store'
require 'async_cache/workers/base'
require 'async_cache/railtie' if defined?(Rails)
