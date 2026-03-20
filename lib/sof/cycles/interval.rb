# frozen_string_literal: true

# Captures the logic for enforcing the Interval cycle variant
#   E.g. "V1I24MF2026-03-31" means:
#     Complete 1 every 24 months, current window from 2026-03-31.
#     After completion, the consuming app re-anchors from the completion date.
#
# Unlike EndOf, there is no end-of-month rounding.
# Unlike Lookback, the window is anchored to a from_date, not sliding from today.
# Unlike Within, the window is repeating — it re-anchors from the completion date.
module SOF
  module Cycles
    class Interval < Cycle
      @volume_only = false
      @notation_id = "I"
      @kind = :interval
      @valid_periods = %w[D W M Y]

      def self.recurring? = true

      def self.dormant_capable? = true

      def self.description
        "Interval - occurrences within a repeating window that re-anchors from completion date"
      end

      def self.examples
        ["V1I24MF2026-03-31 - once every 24 months from March 31, 2026 (re-anchors after completion)"]
      end

      def to_s
        return dormant_to_s unless active?

        "#{volume}x every #{humanized_span} from #{start_date.to_fs(:american)}"
      end

      # Returns the expiration date for the current window
      #
      # @return [Date, nil] The final date of the current window
      def expiration_of(_ = nil, anchor: nil)
        final_date
      end

      # Is the supplied anchor date within the current window?
      #
      # @return [Boolean] true if the anchor is before or on the final date
      def satisfied_by?(_ = nil, anchor: Date.current)
        anchor <= final_date
      end

      # Returns the from_date as the last completed date
      def last_completed(_ = nil) = from_date&.to_date

      # Calculates the final date of the current window
      #
      # @return [Date] from_date + period (no end-of-month rounding)
      #
      # @example
      #   Cycle.for("V1I24MF2026-03-31").final_date
      #   # => #<Date: 2028-03-31>
      def final_date(_ = nil)
        return nil if start_date.nil?
        time_span.end_date(start_date)
      end

      def start_date(_ = nil) = from_date&.to_date

      private

      def dormant_to_s
        "#{volume}x every #{humanized_span}"
      end
    end
  end
end
