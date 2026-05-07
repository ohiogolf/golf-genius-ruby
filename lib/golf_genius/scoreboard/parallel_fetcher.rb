# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Bounded parallel fetch helper for small scoreboard fan-out.
    module ParallelFetcher
      MAX_PARALLEL_REQUESTS = 4

      # Raised when one or more parallel scoreboard fetches fail.
      class Error < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          suffix = errors.size == 1 ? "" : "s"
          messages = errors.map(&:message).join(" | ")

          super("Parallel scoreboard fetch failed with #{errors.size} error#{suffix}: #{messages}")
        end
      end

      module_function

      def fetch_hash(tasks)
        return tasks.transform_values(&:call) if tasks.size < 2

        map(tasks.to_a) { |(key, task)| [key, task.call] }.to_h
      end

      def map(items, &block)
        return items.map { |item| block.call(item) } if items.size < 2

        results = Array.new(items.size)
        errors = []
        mutex = Mutex.new

        # Scoreboards only fan out across a small number of event-level reads.
        # Keep the thread count bounded so a future wider caller does not flood
        # the Golf Genius API or exhaust the shared Faraday connection pool.
        items.each_slice(MAX_PARALLEL_REQUESTS).with_index do |batch, batch_offset|
          threads = batch.each_with_index.map do |item, index|
            Thread.new do
              result_index = (batch_offset * MAX_PARALLEL_REQUESTS) + index
              results[result_index] = block.call(item)
            rescue StandardError => e
              mutex.synchronize { errors << e }
            end
          end

          threads.each(&:join)
        end

        raise Error, errors unless errors.empty?

        results
      end
    end
  end
end
