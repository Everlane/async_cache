module AsyncCache
  module Workers
    class SidekiqWorker
      include ::Sidekiq::Worker

      # Only allow one job per set of arguments to ever be in the queue
      sidekiq_options :unique => :until_executed

      # key             - String or array cache key computed by `AsyncCache`
      # version         - Monotonically increasing integer indicating the version
      #                   of the resource being cached
      # expires_in      - Optional expiration to pass to the cache store
      # block_arguments - Arguments with which to call the block
      # block_source    - Ruby source to evaluate to produce the value
      def perform key, version, expires_in, block_arguments, block_source
        t0 = Time.now

        _cached_data, cached_version = self.class.backend.read key
        return unless version > (cached_version || 0)

        value = [eval(block_source).call(*block_arguments), version]

        backend.write key, value, :expires_in => expires_in
      end

      private

        def backend
          AsyncCache.backend
        end
    end
  end
end
