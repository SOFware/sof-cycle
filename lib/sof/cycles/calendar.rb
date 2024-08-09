# frozen_string_literal: true

module SOF
  module Cycles
    class Calendar < Cycle
      @volume_only = false
      @notation_id = "C"
      @kind = :calendar
      @valid_periods = %w[M Q Y]

      class << self
        def frame_of_reference = "total"
      end

      def self.recurring? = true

      def to_s
        "#{volume}x every #{period_count} calendar #{humanized_period}"
      end

      # "Absent further completions, you go red on this date"
      # @return [Date, nil] the date on which the cycle will expire given the
      #   provided completion dates. Returns nil if the cycle is already unsatisfied.
      def expiration_of(completion_dates)
        anchor = completion_dates.max_by(volume) { _1 }.min
        return unless satisfied_by?(completion_dates, anchor:)

        window_end(anchor) + duration
      end

      def final_date(anchor)
        return if anchor.nil?
        time_span.end_date_of_period(anchor.to_date)
      end
      alias_method :window_end, :final_date

      def start_date(anchor)
        time_span.begin_date_of_period(anchor.to_date)
      end
    end
  end
end
