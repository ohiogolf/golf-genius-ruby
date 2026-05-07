# frozen_string_literal: true

require "test_helper"

class ParallelFetcherTest < Minitest::Test
  def test_fetch_hash_short_circuits_single_task
    called = []

    result = GolfGenius::Scoreboard::ParallelFetcher.fetch_hash(
      one: lambda do
        called << :one
        1
      end
    )

    assert_equal({ one: 1 }, result)
    assert_equal [:one], called
  end

  def test_map_short_circuits_single_item
    called = []

    result = GolfGenius::Scoreboard::ParallelFetcher.map([1]) do |item|
      called << item
      item * 2
    end

    assert_equal [2], result
    assert_equal [1], called
  end

  def test_map_preserves_result_order_across_batches
    items = (0...(GolfGenius::Scoreboard::ParallelFetcher::MAX_PARALLEL_REQUESTS + 2)).to_a

    result = GolfGenius::Scoreboard::ParallelFetcher.map(items) do |item|
      sleep(((items.length - item) % 3) * 0.005)
      item * 10
    end

    assert_equal items.map { |item| item * 10 }, result
  end

  def test_map_raises_aggregate_error_with_all_worker_exceptions
    error = assert_raises(GolfGenius::Scoreboard::ParallelFetcher::Error) do
      GolfGenius::Scoreboard::ParallelFetcher.map(%i[a b c]) do |item|
        case item
        when :a
          raise ArgumentError, "bad a"
        when :b
          raise "bad b"
        else
          :ok
        end
      end
    end

    assert_equal 2, error.errors.size
    assert_equal [ArgumentError, RuntimeError], error.errors.map(&:class).sort_by(&:name)
    assert_includes error.errors.map(&:message), "bad a"
    assert_includes error.errors.map(&:message), "bad b"
  end

  def test_map_never_exceeds_max_parallel_requests
    items = (0...(GolfGenius::Scoreboard::ParallelFetcher::MAX_PARALLEL_REQUESTS * 3)).to_a
    active = 0
    max_active = 0
    mutex = Mutex.new

    GolfGenius::Scoreboard::ParallelFetcher.map(items) do |item|
      mutex.synchronize do
        active += 1
        max_active = [max_active, active].max
      end

      sleep 0.005
      item
    ensure
      mutex.synchronize { active -= 1 }
    end

    assert_operator max_active, :<=, GolfGenius::Scoreboard::ParallelFetcher::MAX_PARALLEL_REQUESTS
  end
end
