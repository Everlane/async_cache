module AsyncCache
  class Store
    attr_accessor :backend

    def initialize(opts)
      @backend = opts[:backend] || Rails.cache
    end

    def fetch(locator, version, options = {}, &block)
			options = options.dup  # Duplicate to avoid side effects
			version = version.to_i # Versions must *always* be convertible to integers

			# Expires-in must be an integer if present, nil if not
			expires_in = options[:expires_in] ? options[:expires_in].to_i : nil

			block_arguments = check_arguments(options.delete(:arguments) || [])

			# Serialize arguments into the full cache key
			key = ActiveSupport::Cache.expand_cache_key Array.wrap(locator) + block_arguments

			cached_data, cached_version = @backend.read key

			strategy = determine_strategy(
				:has_cached_data   => !!cached_data,
				:needs_regen       => version > (cached_version || 0),
				:synchronous_regen => options[:synchronous_regen]
			)

			context = {
				:key        => key,
				:version    => version,
				:expires_in => expires_in,
				:block      => block,
				:arguments  => block_arguments
			}

			case strategy
			when :generate
				return generate_and_cache context

			when :enqueue
				enqueue_generation context
				return cached_data

			when :current
				return cached_data
			end
		end

		def determine_strategy(has_cached_data:, needs_regen:, synchronous_regen:)
			case
			when !has_cached_data
				# Not present at all
				:generate
			when needs_regen && synchronous_regen
				# Caller has indicated we should synchronously regenerate
				:generate
			when needs_regen && !has_workers?
				# No workers available to regnerate, so do it ourselves; we'll log a
				# warning message that we can alert on
				Rails.logger.warn "No Sidekiq workers running to handle queue '#{target_queue}'"
				:generate
			when needs_regen
				:enqueue
			else
				:current
			end
		end

		def generate_and_cache(key:, version:, expires_in:, block:, arguments:)
			# Mimic the destruction-of-scope behavior of the worker in development
			# so it will *fail* for developers if they try to depend upon scope
			block = eval(block.to_source)

			data = block.call(*arguments)

			entry = [data, version]
			@backend.write key, entry, :expires_in => expires_in

			return data
		end

		def enqueue_generation(key:, version:, expires_in:, block:, arguments:)
      AsyncCacheSidekiqWorker.perform_async key, version, expires_in, block, arguments
		end

    private

      def target_queue
        AsyncCacheSidekiqWorker.sidekiq_options['queue'].to_s
      end

			# Use the Sidekiq API to see if there are worker processes available to
			# handle the async cache jobs queue.
			def has_workers?
				processes = Sidekiq::ProcessSet.new.to_a
				queues_being_processed = processes.flat_map { |p| p['queues'] }

				if queues_being_processed.include? target_queue
					true
				else
					false
				end
			end

			# Ensure the arguments are primitives, we don't want to be sending complex
			# data through Sidekiq!
			def check_arguments arguments
				arguments.each_with_index do |argument, index|
					next if argument.is_a? Numeric
					next if argument.is_a? String
					next if argument.is_a? Symbol

					raise ArgumentError, "Cannot send complex data for block argument #{index + 1}: #{argument.class.name}"
				end

				arguments
			end

  end # class Store
end # class AsyncCache
