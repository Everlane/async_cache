# async_cache

Caching is great, but having to block your app while you refresh the cache isn't so great, especially when it takes a long time to regenerate that cache entry.

This outlines a strategy and provides a Rails-focused implementation for asynchronously refreshing caches while serving the stale version to users to maintain responsiveness.

## Usage

Add the gem to your Gemfile:

```ruby
gem 'async_cache'
```

Then set up a store and fetch from it:

```ruby
# (in config/initializers/async_cache.rb)
ASYNC_CACHE = AsyncCache::Store.new(
  backend: Rails.cache,
  worker:  :active_job
)

# (in app/controllers/things_controller.rb)
def show
  # Then use it to do some heavy lifting asychronously
  id      = params[:id]
  key     = "thing/#{id}"
  version = Thing.select(:updated_at).find(id).updated_at

  json = ASYNC_CACHE.fetch(key, version, arguments: [id]) do |id|
    Thing.find(id).to_json
  end

  render body: json, content_type: 'application/json'
end
```

For additional examples see the [`examples`](examples/) folder.

## Strategy

Async-cache follows a straightforward strategy for determining which action to take when a cache entry is fetched:

- If no entry is present it *synchronously* generates the entry, writes it to the cache, and returns it.
- If an old version of the entry is present it enqueues an asynchronous job to refresh the entry and returns the old version.
- If an up-to-date version of the entry is present it serves that.

The implementation includes a few nuances to the strategy: such as checking if workers are running and allowing clients to specify that it should always synchronously-regenerate (useful in things like CMSes where you always want to immediately render the latest version to the user editing it).

### Cache Structure

Async-caching requires a different cache structure than traditional caching.

In traditional caching—here using Rails idioms—the cache for the model "Thing" would look like the following:

- A cache key, such as `things/123-20151210063911000000000`, where the key is comprised of the name of the model, the ID of the instance in question, and the last-modified time (`updated_at`) as an integer
- A cache value containing the actual rendered data for that model instance

In async-caching the cache must be comprised of three parts:

- A cache locator, such as `things/123`
- A version, such as `20151210063911000000000` (using the last-modified time works perfectly for this)
- The cache value

The locator must be constant in async-caching so that we can always retrieve a cache record (version and value) for the given locator. The cache record is then not just a value, but also has the metadata of the version which describes which version-of-the-locator the value applies to. By having this version metadata we're able to determine whether the cache is up-to-date or out-of-date.

##### Example

The following is a simplified example of how values would be cached in Rails in the traditional and async structures:

```ruby
value = compute_some_expensive_value

# Traditional
key = "things/#{thing.id}-#{thing.updated_at.to_i}"

Rails.cache.write key, value

# Async
locator = "things/#{thing.id}"
version = thing.updated_at.to_i

Rails.cache.write key, [version, value]
```

## License

Released under the MIT license, see [LICENSE](LICENSE) for details.
