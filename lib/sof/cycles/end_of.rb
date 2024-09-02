# frozen_string_literal: true

# Captures the logic for enforcing the EndOf cycle variant
#   E.g. "V1E18MF2020-01-05" means:
#     You're good until the end of the 17th subsequent month from 2020-01-05.
#     Complete 1 by that date to reset the cycle.
#
# Some of the calculations are quite different from other cycles.
# Whereas other cycles look at completion dates to determine if the cycle is
# satisfied, this cycle checks whether the anchor date is prior to the final date.
module SOF
  module Cycles
    class EndOf < Cycle
      @volume_only = false
      @notation_id = "E"
      @kind = :end_of
      @valid_periods = %w[W M Q Y]

      def self.recurring? = true

      def to_s
        return dormant_to_s if dormant?

        "#{volume}x by #{final_date.to_fs(:american)}"
      end

      # Always returns the from_date
      def last_completed(_ = nil) = from_date&.to_date

      # Returns the expiration date for the cycle
      #
      # @param [nil] _ Unused parameter, maintained for compatibility
      # @param anchor [nil] _ Unused parameter, maintained for compatibility
      # @return [Date] The final date of the cycle
      #
      # @example
      #   Cycle.for("V1E18MF2020-01-09")
      #     .expiration_of(anchor: "2020-06-04".to_date)
      #   # => #<Date: 2021-06-30>
      def expiration_of(_ = nil, anchor: nil) = final_date

      # Is the supplied anchor date prior to the final date?
      #
      # @return [Boolean] true if the cycle is satisfied, false otherwise
      def satisfied_by?(_ = nil, anchor: Date.current) = anchor <= final_date

      # Calculates the final date of the cycle
      #
      # @param [nil] _ Unused parameter, maintained for compatibility
      # @return [Date] The final date of the cycle calculated as the end of the
      #   nth subsequent period after the FROM date, where n = (period count - 1)
      #
      # @example
      #   Cycle.for("V1E18MF2020-01-09").final_date
      #   # => #<Date: 2021-06-30>
      def final_date(_ = nil) = time_span
        .end_date(start_date - 1.send(period))
        .end_of_month

      def start_date(_ = nil) = from_date.to_date

      private

      def dormant_to_s
        <<~DESC.squish
          #{volume}x by the last day of the #{subsequent_ordinal}
          subsequent #{period}
        DESC
      end

      def subsequent_ordinal
        ActiveSupport::Inflector.ordinalize(period_count - 1)
      end
    end
  end
end
