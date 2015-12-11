require 'sidekiq/api'

module AsyncCache
  module Workers
    class SidekiqWorker < Base
      include ::Sidekiq::Worker

      # Only allow one job per set of arguments to ever be in the queue
      sidekiq_options :unique => :until_executed

      # Use the Sidekiq API to see if there are worker processes available to
      # handle the async cache jobs queue.
      def self.has_workers?
        target_queue = self.sidekiq_options['queue'].to_s

        processes = Sidekiq::ProcessSet.new.to_a
        queues_being_processed = processes.flat_map { |p| p['queues'] }

        if queues_being_processed.include? target_queue
          true
        else
          false
        end
      end

      def self.enqueue_async_job(key:, version:, expires_in:, block:, arguments:)
        self.perform_async key, version, expires_in, arguments, block
      end

      # key             - String or array cache key computed by `AsyncCache`
      # version         - Monotonically increasing integer indicating the version
      #                   of the resource being cached
      # expires_in      - Optional expiration to pass to the cache store
      # block_arguments - Arguments with which to call the block
      # block_source    - Ruby source to evaluate to produce the value
      def perform key, version, expires_in, block_arguments, block_source
        t0 = Time.now

        _cached_data, cached_version = backend.read key
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
