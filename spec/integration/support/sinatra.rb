require 'sinatra'
require 'securerandom'

require_relative './config'

store = nil

configure do
  store = AsyncCache::Store.new worker: :sidekiq
end

def get_file_version(path)
  File.mtime(path).to_i
end

get '/' do
  locator = LOCATOR
  version = get_file_version VERSION_PATH

  store.fetch(locator, version) do
    SecureRandom.uuid
  end
end
