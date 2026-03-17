# frozen_string_literal: true

# Captures the logic for enforcing the Recurring cycle variant
#   E.g. "V1R24MF2026-03-31" means:
#     Complete 1 within 24 months starting from 2026-03-31.
#     After completion, the next window starts from the completion date.
#
# Unlike EndOf, there is no end-of-month rounding.
# Unlike Lookback, the window is anchored to a from_date, not sliding from today.
module SOF
  module Cycles
    class Recurring < Cycle
      @volume_only = false
      @notation_id = "R"
      @kind = :recurring
      @valid_periods = %w[D W M Y]

      def self.recurring? = true

      def self.description
        "Recurring - occurrences within a recurring time period anchored to a from date"
      end

      def self.examples
        ["V1R24MF2026-03-31 - once within 24 months from March 31, 2026"]
      end

      def to_s
        return dormant_to_s if parser.dormant? || from_date.nil?

        "#{volume}x within #{date_range}"
      end

      # Returns the expiration date for the cycle
      #
      # @return [Date, nil] The final date of the current window
      def expiration_of(_ = nil, anchor: nil)
        return nil if parser.dormant? || from_date.nil?
        final_date
      end

      # Is the supplied anchor date within the current window?
      #
      # @return [Boolean] true if the anchor is before or on the final date
      def satisfied_by?(_ = nil, anchor: Date.current)
        return false if parser.dormant? || from_date.nil?
        anchor <= final_date
      end

      # Always returns the from_date
      def last_completed(_ = nil) = from_date&.to_date

      # Calculates the final date of the current window
      #
      # @return [Date] from_date + period (no end-of-month rounding)
      #
      # @example
      #   Cycle.for("V1R24MF2026-03-31").final_date
      #   # => #<Date: 2028-03-31>
      def final_date(_ = nil)
        return nil if parser.dormant? || from_date.nil?
        time_span.end_date(start_date)
      end

      def start_date(_ = nil) = from_date&.to_date

      private

      def dormant_to_s
        <<~DESC.squish
          #{volume}x every #{humanized_span}
        DESC
      end

      def date_range
        [start_date, final_date].map { it.to_fs(:american) }.join(" - ")
      end
    end
  end
end
