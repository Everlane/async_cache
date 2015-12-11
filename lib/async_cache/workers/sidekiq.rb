require 'sidekiq'
require 'sidekiq/api'

module AsyncCache
  module Workers
    class SidekiqWorker
      include Base
      include Sidekiq::Worker

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

    end # class SidekiqWorker
  end
end
