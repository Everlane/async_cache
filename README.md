# async_cache

Caching is great, but having to block your app while you refresh the cache isn't so great, especially when it takes a long time to regenerate that cache entry.

This outlines a strategy and provides a Rails-focused implementation for asynchronously refreshing caches while serving the stale version to users to maintain responsiveness.

## Strategy

Async-cache follows a straightforward strategy for determining which action to take when a cache entry is fetched:

- If no entry is present it *synchronously* generates the entry, writes it to the cache, and returns it.
- If an old version of the entry is present it enqueues an asynchronous job to refresh the entry and returns the old version.
- If an up-to-date version of the entry is present it serves that.

The implementation includes a few nuances to the strategy: such as checking if workers are running and allowing clients to specify that it should always synchronously-regenerate (useful in things like CMSes where you always want to immediately render the latest version to the user editing it).

## License

Released under the MIT license, see [LICENSE](LICENSE) for details.
