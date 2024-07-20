# frozen_string_literal: true

module SOF
  module Cycles
    class Lookback < Cycle
      @volume_only = false
      @notation_id = "L"
      @kind = :lookback
      @valid_periods = %w[D W M Y]

      def to_s = "#{volume}x in the prior #{period_count} #{humanized_period}"

      def volume_to_delay_expiration(completion_dates, anchor:)
        oldest_relevant_completion = completion_dates.min
        [completion_dates.count(oldest_relevant_completion), volume].min
      end

      # "Absent further completions, you go red on this date"
      # @return [Date, nil] the date on which the cycle will expire given the
      #   provided completion dates. Returns nil if the cycle is already unsatisfied.
      def expiration_of(completion_dates)
        anchor = completion_dates.max_by(volume) { _1 }.min
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
