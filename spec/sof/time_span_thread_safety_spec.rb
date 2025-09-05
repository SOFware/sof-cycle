# frozen_string_literal: true

require "spec_helper"

RSpec.describe SOF::TimeSpan do
  describe "thread safety" do
    describe "TimeSpan.for" do
      it "safely creates TimeSpan instances concurrently" do
        results = Concurrent::Array.new
        errors = []

        threads = 100.times.map do |i|
          Thread.new do
            count = i % 10
            period = ["D", "W", "M"][i % 3]
            result = described_class.for(count, period)
            results << result
          rescue => e
            errors << e
          end
        end

        threads.each(&:join)

        expect(errors).to be_empty
        expect(results.size).to eq(100)

        # Verify correct class is returned based on count
        results.each_with_index do |result, i|
          count = i % 10
          case count
          when 0
            expect(result).to be_a(SOF::TimeSpan::TimeSpanNothing)
          when 1
            expect(result).to be_a(SOF::TimeSpan::TimeSpanOne)
          else
            expect(result).to be_a(SOF::TimeSpan)
          end
        end
      end
    end

    describe "TimeSpan.notation_id_from_name" do
      it "safely looks up notation IDs concurrently" do
        names = [:day, :week, :month, :quarter, :year]
        results = Concurrent::Array.new
        errors = []

        threads = 100.times.map do |i|
          Thread.new do
            name = names[i % names.size]
            result = described_class.notation_id_from_name(name)
            results << [name, result]
          rescue => e
            errors << e
          end
        end

        threads.each(&:join)

        expect(errors).to be_empty
        expect(results.size).to eq(100)

        # Verify correct mappings
        expected_mappings = {
          day: "D",
          week: "W",
          month: "M",
          quarter: "Q",
          year: "Y"
        }

        results.each do |name, code|
          expect(code).to eq(expected_mappings[name])
        end
      end

      it "raises InvalidPeriod for unknown periods even under concurrent access" do
        errors = Concurrent::Array.new

        threads = 10.times.map do
          Thread.new do
            described_class.notation_id_from_name(:invalid_period)
          rescue SOF::TimeSpan::InvalidPeriod => e
            errors << e
          end
        end

        threads.each(&:join)

        expect(errors.size).to eq(10)
        errors.each do |error|
          expect(error.message).to include("'invalid_period' is not a valid period")
        end
      end
    end

    describe "TimeSpan instance methods" do
      let(:time_span) { described_class.for(3, "D") }
      let(:test_date) { Date.new(2024, 1, 15) }

      it "safely calculates end_date concurrently" do
        results = Concurrent::Array.new
        errors = []

        threads = 50.times.map do
          Thread.new do
            result = time_span.end_date(test_date)
            results << result
          rescue => e
            errors << e
          end
        end

        threads.each(&:join)

        expect(errors).to be_empty
        expect(results.size).to eq(50)
        # All results should be the same
        expect(results.uniq.size).to eq(1)
        expect(results.first).to eq(test_date + 3.days)
      end

      it "safely calculates begin_date concurrently" do
        results = Concurrent::Array.new
        errors = []

        threads = 50.times.map do
          Thread.new do
            result = time_span.begin_date(test_date)
            results << result
          rescue => e
            errors << e
          end
        end

        threads.each(&:join)

        expect(errors).to be_empty
        expect(results.size).to eq(50)
        # All results should be the same
        expect(results.uniq.size).to eq(1)
        expect(results.first).to eq(test_date - 3.days)
      end

      it "handles multiple dates concurrently" do
        dates = 10.times.map { |i| Date.new(2024, 1, i + 1) }
        results = Concurrent::Hash.new
        errors = []

        threads = dates.flat_map do |date|
          # Multiple threads for each date
          5.times.map do
            Thread.new do
              results[date] ||= []
              results[date] << time_span.end_date(date)
            rescue => e
              errors << e
            end
          end
        end

        threads.each(&:join)

        expect(errors).to be_empty

        # Verify each date has consistent results
        dates.each do |date|
          date_results = results[date]
          expect(date_results).not_to be_nil
          expect(date_results.uniq.size).to eq(1)
          expect(date_results.first).to eq(date + 3.days)
        end
      end

      it "handles final_date calculations concurrently" do
        results = Concurrent::Array.new
        errors = []

        threads = 50.times.map do
          Thread.new do
            result = time_span.final_date(test_date)
            results << result
          rescue => e
            errors << e
          end
        end

        threads.each(&:join)

        expect(errors).to be_empty
        expect(results.size).to eq(50)
        # All results should be the same
        expect(results.uniq.size).to eq(1)
        expect(results.first).to eq(test_date + 3.days)
      end
    end

    describe "TimeSpan.notation" do
      it "safely creates notation strings concurrently" do
        test_hashes = [
          {period: "day", period_count: 1},
          {period: "week", period_count: 2},
          {period: "month", period_count: 3},
          {period: "quarter", period_count: 4},
          {period: "year", period_count: 5}
        ]

        results = Concurrent::Array.new
        errors = []

        threads = 100.times.map do |i|
          Thread.new do
            hash = test_hashes[i % test_hashes.size]
            result = described_class.notation(hash)
            results << [hash, result]
          rescue => e
            errors << e
          end
        end

        threads.each(&:join)

        expect(errors).to be_empty
        expect(results.size).to eq(100)

        expected_notations = {
          "day" => "1D",
          "week" => "2W",
          "month" => "3M",
          "quarter" => "4Q",
          "year" => "5Y"
        }

        results.each do |hash, notation|
          period = hash[:period]
          expected = expected_notations[period]
          expect(notation).to eq(expected)
        end
      end
    end

    describe "Multiple TimeSpan instances" do
      it "safely creates and uses multiple TimeSpan instances concurrently" do
        errors = []
        results = Concurrent::Hash.new

        threads = []

        # Create different TimeSpan instances
        ["D", "W", "M"].each do |period|
          [1, 2, 3].each do |count|
            threads << Thread.new do
              time_span = described_class.for(count, period)
              test_date = Date.new(2024, 1, 15)

              # Perform multiple operations
              10.times do
                key = "#{count}#{period}"
                results[key] ||= Concurrent::Array.new
                results[key] << time_span.end_date(test_date)
                results[key] << time_span.begin_date(test_date)
                results[key] << time_span.final_date(test_date)
              end
            rescue => e
              errors << e
            end
          end
        end

        threads.each(&:join)

        expect(errors).to be_empty

        # Verify consistency for each time_span
        results.each do |key, values|
          end_dates = values.select.with_index { |_, i| i % 3 == 0 }
          begin_dates = values.select.with_index { |_, i| i % 3 == 1 }
          final_dates = values.select.with_index { |_, i| i % 3 == 2 }

          expect(end_dates.uniq.size).to eq(1)
          expect(begin_dates.uniq.size).to eq(1)
          expect(final_dates.uniq.size).to eq(1)
        end
      end
    end
  end
end
