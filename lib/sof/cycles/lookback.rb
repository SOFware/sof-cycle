# frozen_string_literal: true

module SOF
  module Cycles
    class Lookback < Cycle
      @volume_only = false
      @notation_id = "L"
      @kind = :lookback
      @valid_periods = %w[D W M Y]

      def self.recurring? = true

      def self.description
        "Lookback - occurrences within a prior time period counting backwards from today"
      end

      def self.examples
        ["V3L3D - 3 times in the prior 3 days", "V1L2W - once in the prior 2 weeks"]
      end

      def to_s = "#{volume}x in the prior #{period_count} #{humanized_period}"

      def volume_to_delay_expiration(completion_dates, anchor:)
        relevant_dates = considered_dates(completion_dates, anchor:)
        return unless satisfied_by?(relevant_dates, anchor:)

        # To move the expiration date, we need to displace each occurance of the
        # oldest date within #considered_dates.
        relevant_dates.count(relevant_dates.min)
      end

      # "Absent further completions, you go red on this date"
      # @return [Date, nil] the date on which the cycle will expire given the
      #   provided completion dates. Returns nil if the cycle is already unsatisfied.
      def expiration_of(completion_dates)
        anchor = completion_dates.max_by(volume) { it }.min
        return unless satisfied_by?(completion_dates, anchor:)

        window_end anchor
      end

      def final_date(anchor)
        return if anchor.nil?

        time_span.end_date(anchor.to_date)
      end
      alias_method :window_end, :final_date

      def start_date(anchor)
        time_span.begin_date(anchor.to_date)
      end
      alias_method :window_start, :start_date
    end
  end
end
