require 'digest/md5'

module AsyncCache
  class Store
    attr_accessor :backend, :worker_klass

    # Global index of store instances
    def self.stores
      @stores ||= []
    end

    # @param [Hash] opts Initialization options
    # @option opts [Object] :backend The backend that it will read/write
    #   entries to/from
    # @option opts [Symbol] :worker Shorthand symbol for the worker to use,
    #   options are `:active_job` and `:sidekiq`.
    # @option ops [Class] :worker_klass Class of the worker to use.
    def initialize(opts = {})
      @worker_klass =
        if opts[:worker_klass]
          opts[:worker_klass]
        elsif opts[:worker]
          AsyncCache::Workers.worker_for_name opts[:worker]
        else
          raise ArgumentError, 'Must have a :worker_klass or :worker option'
        end

      @backend = opts[:backend] || AsyncCache.backend

      # Register ourselves in the array of known store instances
      self.class.stores << self
    end

    # @param [String] locator The constant locator for the entry in the cache
    # @param [Fixnum] version Version of the value identified by that locator
    # @param [Hash] options
    # @yield [*arguments in options[:arguments]] Called if entry out-of-date
    def fetch(locator, version, options = {}, &block)
      options = options.dup  # Duplicate to avoid side effects
      version = version.to_i # Versions must *always* be convertible to integers

      # Expires-in must be an integer if present, nil if not
      expires_in = options[:expires_in] ? options[:expires_in].to_i : nil

      block_source    = block.to_source
      block_arguments = check_arguments(options.delete(:arguments) || [])

      full_key = [
        locator,
        Digest::MD5.hexdigest(block_source),
        block_arguments
      ].flatten

      # Serialize arguments into the full cache key
      key = ActiveSupport::Cache.expand_cache_key full_key

      cached_data, cached_version = @backend.read key

      strategy = determine_strategy(
        :has_cached_data   => !!cached_data,
        :needs_regen       => version > (cached_version || 0),
        :synchronous_regen => options[:synchronous_regen]
      )

      return cached_data if strategy == :current

      context = {
        :key          => key,
        :version      => version,
        :expires_in   => expires_in,
        :block_source => block_source,
        :arguments    => block_arguments
      }

      case strategy
      when :generate
        return generate_and_cache context
      when :enqueue
        enqueue_generation context
        return cached_data
      end
    end

    def clear
      @worker_klass.clear
    end

    def determine_strategy(has_cached_data:, needs_regen:, synchronous_regen:)
      case
      when !has_cached_data
        # Not present at all
        :generate
      when needs_regen && synchronous_regen
        # Caller has indicated we should synchronously regenerate
        :generate
      when needs_regen && !worker_klass.has_workers?
        # No workers available to regnerate, so do it ourselves; we'll log a
        # warning message that we can alert on
        AsyncCache.logger.warn "No workers running to handle AsyncCache jobs"
        :generate
      when needs_regen
        :enqueue
      else
        :current
      end
    end

    def generate_and_cache(key:, version:, expires_in:, block_source:, arguments:)
      # Mimic the destruction-of-scope behavior of the worker in development
      # so it will *fail* for developers if they try to depend upon scope
      block = eval(block_source)

      data = block.call(*arguments)

      entry = [data, version]
      @backend.write key, entry, :expires_in => expires_in

      return data
    end

    def enqueue_generation(key:, version:, expires_in:, block_source:, arguments:)
      worker_klass.enqueue_async_job(
        key:        key,
        version:    version,
        expires_in: expires_in,
        block:      block_source,
        arguments:  arguments
      )
    end

    def inspect
      pointer_format  = '0x%014x'
      pointer         = Kernel.sprintf pointer_format, self.object_id * 2
      backend_pointer = Kernel.sprintf pointer_format, @backend.object_id * 2

      '#<' + [
        "#{self.class.name}:#{pointer} ",
        "@worker_klass=#{@worker_klass.name}, ",
        "@backend=#<#{@backend.class.name}:#{backend_pointer}>"
      ].join('') + '>'
    end

    private

      # Ensures the arguments are primitives.
      def check_arguments arguments
        arguments.each_with_index do |argument, index|
          next if argument.is_a? Numeric
          next if argument.is_a? String
          next if argument.is_a? Symbol
          next if argument.is_a? Hash
          next if argument.is_a? NilClass
          next if argument.is_a? TrueClass
          next if argument.is_a? FalseClass

          raise ArgumentError, "Cannot send complex data for block argument #{index + 1}: #{argument.class.name}"
        end

        arguments
      end

  end # class Store
end # class AsyncCache
