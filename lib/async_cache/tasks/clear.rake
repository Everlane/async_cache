namespace :async_cache do
  prereqs =
    if defined?(Rails)
      [:environment]
    else
      []
    end

  desc 'Clear the worker queues'
  task :clear => prereqs do
    AsyncCache::Store.stores.each do |store|
      store.clear
      puts "Cleared #{store.inspect}"
    end
  end
end
