# frozen_string_literal: true

module SOF
  module Cycles
    class Within < Cycle
      @volume_only = false
      @notation_id = "W"
      @kind = :within
      @valid_periods = %w[D W M Y]

      def self.recurring? = false

      def self.description
        "Within - occurrences within a time period from a specific date"
      end

      def self.examples
        ["V2W3DF2024-01-01 - twice within 3 days from Jan 1, 2024"]
      end

      def to_s = "#{volume}x within #{date_range}"

      def extend_period(count)
        Cycle.for(
          Parser.load(
            parser.to_h.merge(period_count: period_count + count)
          ).to_s
        )
      end

      def date_range
        return humanized_span unless active?

        [start_date, final_date].map { it.to_fs(:american) }.join(" - ")
      end

      def final_date(_ = nil) = time_span.end_date(start_date)

      def start_date(_ = nil) = from_date.to_date
    end
  end
end
