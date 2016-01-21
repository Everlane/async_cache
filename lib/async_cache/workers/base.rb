require 'active_support/core_ext/array/wrap'

module AsyncCache
  module Workers
    def self.worker_for_name(name)
      case name
      when :sidekiq
        require 'async_cache/workers/sidekiq'
        AsyncCache::Workers::SidekiqWorker
      when :active_job
        require 'async_cache/workers/active_job'
        AsyncCache::Workers::ActiveJobWorker
      else
        raise "Worker not found: #{name.inspect}"
      end
    end

    module Base
      # Abstract public interface to workers that process AsyncCache jobs

      # @return [Boolean] Returns whether or not workers are running to
      #   process enqueue AsyncCache jobs. Return `false` if this
      #   functionality isn't available by the underlying system.
      def self.has_workers?
        raise NotImplementedError
      end

      # Clear the active jobs from this worker's queue.
      def self.clear
        raise NotImplementedError
      end

      # Public interface for enqueuing jobs. This is what is called by
      # {AsyncCache::Store}.
      def self.enqueue_async_job(key:, version:, expires_in:, block:, arguments:)
        raise NotImplementedError
      end

      # @param [String] key String or array cache key computed by `AsyncCache`
      # @param [Fixnum] version Monotonically increasing integer indicating
      #   the version of the resource being cached
      # @param [Fixnum] expires_in Optional expiration to pass to the cache store
      # @param [Array] block_arguments Arguments with which to call the block
      # @param [String] block_source Ruby source to evaluate to produce the value
      def perform key, version, expires_in, block_arguments, block_source
        _cached_data, cached_version = backend.read key
        return unless version > (cached_version || 0)

        value = [eval(block_source).call(*block_arguments), version]

        backend.write key, value, :expires_in => expires_in
      end

      private

      def backend
        AsyncCache.backend
      end

    end # module Base
  end
end
