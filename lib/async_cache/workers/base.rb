module AsyncCache
  module Workers
    class Base
      # Abstract public interface to workers that process AsyncCache jobs

      def self.has_workers?
        raise NotImplementedError
      end

      def self.enqueue_async_job(key:, version:, expires_in:, block:, arguments:)
        raise NotImplementedError
      end
    end
  end
end
