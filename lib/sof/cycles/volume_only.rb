# frozen_string_literal: true

module SOF
  module Cycles
    class VolumeOnly < Cycle
      @volume_only = true
      @notation_id = nil
      @kind = :volume_only
      @valid_periods = []

      class << self
        def handles?(sym) = sym.nil? || super

        def validate_period(period)
          raise InvalidPeriod, <<~ERR.squish unless period.nil?
            Invalid period value of '#{period}' provided. Valid periods are:
            #{valid_periods.join(", ")}
          ERR
        end
      end

      def to_s = "#{volume}x total"

      def covered_dates(dates, ...) = dates

      def cover?(...) = true
    end
  end
end
