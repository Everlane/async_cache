require 'bundler/setup'

require 'rails'
require 'sidekiq'
require 'sidekiq/testing'
require 'simplecov'

Sidekiq::Testing.inline!
SimpleCov.start

Rails.cache  = ActiveSupport::Cache::MemoryStore.new
Rails.logger = Logger.new($stdout).tap { |log| log.level = Logger::ERROR }

require 'async_cache'
