require 'sourcify'

module AsyncCache
  class << self
    def backend
      @backend || Rails.cache
    end
    def backend=(backend)
      @backend = backend
    end

    def logger
      @logger || Rails.logger
    end
    def logger=(logger)
      @logger = logger
    end
  end
end

require 'async_cache/version'
require 'async_cache/store'
