# frozen_string_literal: true

module SOF
  module Cycles
    class Within < Cycle
      @volume_only = false
      @notation_id = "W"
      @kind = :within
      @valid_periods = %w[D W M Y]

      def self.recurring? = false

      def to_s = "#{volume}x within #{date_range}"

      def date_range
        return humanized_span unless active?

        [start_date, final_date].map { _1.to_fs(:american) }.join(" - ")
      end

      def final_date(_ = nil) = time_span.end_date(start_date)

      def start_date(_ = nil) = from_date.to_date
    end
  end
end
