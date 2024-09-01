# frozen_string_literal: true

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
