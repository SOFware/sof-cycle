# frozen_string_literal: true

require_relative "within"

# A Within cycle that repeats — after satisfaction, the consuming app
# re-anchors the window from the completion date.
#
#   E.g. "V1I24MF2026-03-31" means:
#     Complete 1 every 24 months, current window from 2026-03-31.
#     After completion, call reactivated_notation(completion_date) to start
#     the next window.
#
# Inherits final_date, start_date, and date_range from Within.
# Overrides only what differs: recurring?, to_s, extend_period,
# last_completed, expiration_of, and satisfied_by?.
module SOF
  module Cycles
    class RepeatingWithin < Within
      @volume_only = false
      @notation_id = "I"
      @kind = :repeating_within
      @valid_periods = %w[D W M Y]

      def self.recurring? = true

      def self.description
        "RepeatingWithin - like Within, but the window re-anchors from the completion date after satisfaction"
      end

      def self.examples
        ["V1I24MF2026-03-31 - once every 24 months from March 31, 2026 (re-anchors after completion)"]
      end

      # --- Overrides from Within ---

      def to_s
        return dormant_to_s unless active?

        "#{volume}x every #{humanized_span} from #{start_date.to_fs(:american)}"
      end

      # Nil-safe for dormant state (Within assumes active via Dormant wrapper,
      # but Dormant#method_missing passes through final_date/start_date)
      def start_date(_ = nil) = from_date&.to_date

      def final_date(_ = nil)
        return nil if start_date.nil?
        super
      end

      # RepeatingWithin re-anchors instead of extending
      def extend_period(_ = nil) = self

      # The from_date represents when the current window started
      def last_completed(_ = nil) = from_date&.to_date

      # Returns the final date of the current window
      def expiration_of(_ = nil, anchor: nil)
        final_date
      end

      # Is the anchor still within the current window?
      def satisfied_by?(_ = nil, anchor: Date.current)
        anchor <= final_date
      end

      private

      def dormant_to_s
        "#{volume}x every #{humanized_span}"
      end
    end
  end
end
