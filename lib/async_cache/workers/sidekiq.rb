require 'sidekiq'
require 'sidekiq/api'

module AsyncCache
  module Workers
    class SidekiqWorker
      include Base
      include Sidekiq::Worker

      # Pulled out into a module so it can be tested.
      module Options
        def self.included(mod)
          if defined?(Sidekiq::Enterprise)
            mod.sidekiq_options unique_for: AsyncCache.options[:uniqueness_timeout]
          elsif defined?(SidekiqUniqueJobs)
            # Only allow one job per set of arguments to ever be in the queue
            mod.sidekiq_options unique: :until_executed
          end
        end
      end

      include Options

      # Use the Sidekiq API to see if there are worker processes available to
      # handle the async cache jobs queue.
      def self.has_workers?
        processes = Sidekiq::ProcessSet.new.to_a
        queues_being_processed = processes.flat_map { |p| p['queues'] }

        if queues_being_processed.include? sidekiq_queue
          true
        else
          false
        end
      end

      def self.clear
        queue = Sidekiq::Queue.new sidekiq_queue

        queue.clear
      end

      def self.enqueue_async_job(key:, version:, expires_in:, block:, arguments:)
        self.perform_async key, version, expires_in, arguments, block
      end

      private

        def self.sidekiq_queue
          self.sidekiq_options['queue'].to_s
        end

    end # class SidekiqWorker
  end
end
