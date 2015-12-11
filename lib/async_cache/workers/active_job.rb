require 'active_job'

module AsyncCache
  module Workers
    class ActiveJobWorker < ActiveJob::Base
      include Base

      def self.has_workers?
        # ActiveJob doesn't provide a way to see if worker processes are
        # running so we just assume that they are
        true
      end

      def self.enqueue_async_job(key:, version:, expires_in:, block:, arguments:)
        self.perform_later key, version, expires_in, arguments, block
      end

    end # class ActiveJobWorker
  end
end
