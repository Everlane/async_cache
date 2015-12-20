require 'sinatra'

require_relative './sidekiq'

store = nil

configure do
  store = AsyncCache::Store.new worker: :sidekiq
end

def get_file_version(path)
  File.mtime(path).to_i
end

get '/' do
  locator = 'x'
  version = get_file_version File.join(File.dirname(__FILE__), 'version.txt')

  store.fetch(locator, version) do
    Time.now.to_s
  end
end
