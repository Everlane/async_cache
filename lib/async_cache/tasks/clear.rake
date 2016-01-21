namespace :async_cache do
  desc 'Clear the worker queues'
  task :clear do
    AsyncCache::Store.stores.each do |store|
      store.clear
    end
  end
end
