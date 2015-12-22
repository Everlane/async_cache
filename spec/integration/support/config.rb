require 'sidekiq'
require 'async_cache'
require 'async_cache/workers/sidekiq'
require 'rails'
require 'redis-activesupport'

Rails.cache  = ActiveSupport::Cache::RedisStore.new
Rails.logger = Logger.new($stdout).tap { |log| log.level = Logger::WARN }

Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'x', :size => 1 }
end
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'x' }
end

LOCATOR = 'y'
VERSION_PATH = File.join(File.dirname(__FILE__), 'version.txt')
