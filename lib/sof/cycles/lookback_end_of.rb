# frozen_string_literal: true

module SOF
  module Cycles
    class LookbackEndOf < Cycle
      @volume_only = false
      @notation_id = "LE"
      @kind = :lookback_end_of
      @valid_periods = %w[D W M Q Y]

      def self.recurring? = true

      def self.description
        "Lookback End of Period - occurrences within a prior time period, expiring at the end of the calendar period"
      end

      def self.examples
        ["V1LE24M - once in the prior 24 months (expires end of month)", "V2LE3W - twice in the prior 3 weeks (expires end of week)"]
      end

      def to_s = "#{volume}x in the prior #{period_count} #{humanized_period} (end of period)"

      def expiration_of(completion_dates, anchor: Date.current)
        oldest = completion_dates.max_by(volume) { it }.min
        return unless satisfied_by?(completion_dates, anchor:)

        final_date(oldest)
      end

      def final_date(anchor)
        return if anchor.nil?

        time_span.end_date_of_period(time_span.end_date(anchor.to_date))
      end
      alias_method :window_end, :final_date

      def start_date(anchor)
        time_span.begin_date_of_period(time_span.begin_date(anchor.to_date))
      end
      alias_method :window_start, :start_date
    end
  end
end
