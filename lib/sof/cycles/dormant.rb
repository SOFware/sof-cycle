# frozen_string_literal: true

module SOF
  module Cycles
    class Dormant
      def initialize(cycle, parser:)
        @cycle = cycle
        @parser = parser
      end

      attr_reader :cycle, :parser

      def self.recurring? = false

      def kind = :dormant

      def dormant? = true

      def to_s
        cycle.to_s + " (dormant)"
      end

      def covered_dates(...) = []

      def expiration_of(...) = nil

      def satisfied_by?(...) = false

      def cover?(...) = false

      def method_missing(method, ...) = cycle.send(method, ...)

      def respond_to_missing?(method, include_private = false)
        cycle.respond_to?(method, include_private)
      end
    end
  end
end
