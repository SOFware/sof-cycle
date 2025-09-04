# frozen_string_literal: true

require "forwardable"
require_relative "parser"

module SOF
  class Cycle
    extend ::Forwardable
    class InvalidInput < StandardError; end

    class InvalidPeriod < InvalidInput; end

    class InvalidKind < InvalidInput; end

    class << self
      # Turn a cycle or notation string into a hash
      def dump(cycle_or_string)
        if cycle_or_string.is_a? Cycle
          cycle_or_string
        else
          Cycle.for(cycle_or_string)
        end.to_h
      end

      # Return a Cycle object from a hash
      def load(hash)
        symbolized_hash = hash.symbolize_keys
        cycle_class = class_for_kind(symbolized_hash[:kind])

        unless cycle_class.valid_periods.empty?
          cycle_class.validate_period(
            TimeSpan.notation_id_from_name(symbolized_hash[:period])
          )
        end

        Cycle.for notation(symbolized_hash)
      rescue TimeSpan::InvalidPeriod => exc
        raise InvalidPeriod, exc.message
      end

      # Retun a notation string from a hash
      #
      # @param hash [Hash] hash of data for a valid Cycle
      # @return [String] string representation of a Cycle
      def notation(hash)
        volume_notation = "V#{hash.fetch(:volume) { 1 }}"
        return volume_notation if hash[:kind].nil? || hash[:kind].to_sym == :volume_only

        cycle_class = class_for_kind(hash[:kind].to_sym)
        [
          volume_notation,
          cycle_class.notation_id,
          TimeSpan.notation(hash.slice(:period, :period_count)),
          hash.fetch(:from, nil)
        ].compact.join
      end

      # Return a Cycle object from a notation string
      #
      # @param notation [String] a string notation representing a Cycle
      # @example
      #   Cycle.for('V2C1Y)
      # @return [Cycle] a Cycle object representing the provide string notation
      def for(notation)
        return notation if notation.is_a? Cycle
        return notation if notation.is_a? Cycles::Dormant
        parser = Parser.new(notation)
        unless parser.valid?
          raise InvalidInput, "'#{notation}' is not a valid input"
        end

        cycle = cycle_handlers.find do |klass|
          parser.parses?(klass.notation_id)
        end.new(notation, parser:)
        return cycle if parser.active?

        Cycles::Dormant.new(cycle, parser:)
      end

      # Return the appropriate class for the give notation id
      #
      # @param notation [String] notation id matching the kind of Cycle class
      # @example
      #   class_for_notation_id('L')
      #
      def class_for_notation_id(notation_id)
        cycle_handlers.find do |klass|
          klass.notation_id == notation_id
        end || raise(InvalidKind, "'#{notation_id}' is not a valid kind of #{name}")
      end

      # Return the class handling the kind
      #
      # @param sym [Symbol] symbol matching the kind of Cycle class
      # @example
      #   class_for_kind(:lookback)
      def class_for_kind(sym)
        Cycle.cycle_handlers.find do |klass|
          klass.handles?(sym)
        end || raise(InvalidKind, "':#{sym}' is not a valid kind of Cycle")
      end

      # Return a legend explaining all notation components
      #
      # @return [Hash] hash with notation components organized by category
      def legend
        {
          "quantity" => {
            "V" => {
              description: "Volume - the number of times something should occur",
              examples: ["V1L1D - once in the prior 1 day", "V3L3D - three times in the prior 3 days", "V10L10D - ten times in the prior 10 days"]
            }
          },
          "kind" => build_kind_legend,
          "period" => build_period_legend,
          "date" => {
            "F" => {
              description: "From - specifies the anchor date for Within cycles",
              examples: ["F2024-01-01 - from January 1, 2024", "F2024-12-31 - from December 31, 2024"]
            }
          }
        }
      end

      @volume_only = false
      @notation_id = nil
      @kind = nil
      @valid_periods = []

      attr_reader :notation_id, :kind, :valid_periods
      def volume_only? = @volume_only

      def recurring? = raise "#{name} must implement #{__method__}"

      # Raises an error if the given period isn't in the list of valid periods.
      #
      # @param period [String] period matching the class valid periods
      # @raise [InvalidPeriod]
      def validate_period(period)
        raise InvalidPeriod, <<~ERR.squish unless valid_periods.include?(period)
          Invalid period value of '#{period}' provided. Valid periods are:
          #{valid_periods.join(", ")}
        ERR
      end

      def handles?(sym)
        kind.to_s == sym.to_s
      end

      def cycle_handlers
        @cycle_handlers ||= Set.new
      end

      def inherited(klass)
        cycle_handlers << klass
      end

      private

      def build_kind_legend
        legend = {}
        cycle_handlers.each do |handler|
          # Skip volume_only since it doesn't have a notation_id
          next if handler.instance_variable_get(:@volume_only)

          notation_id = handler.instance_variable_get(:@notation_id)
          next unless notation_id

          legend[notation_id] = {
            description: handler.description,
            examples: handler.examples
          }
        end
        legend
      end

      def build_period_legend
        legend = {}
        # Use known period codes since DatePeriod is private
        period_mappings = {
          "D" => "day",
          "W" => "week",
          "M" => "month",
          "Q" => "quarter",
          "Y" => "year"
        }

        period_mappings.each do |code, period_name|
          legend[code] = {
            description: "#{period_name.capitalize} - period notation",
            examples: period_examples_for(code, period_name)
          }
        end
        legend
      end

      def period_examples_for(code, period_name)
        base_example = (code == "D") ? "3#{code} - 3 #{period_name}s" : "2#{code} - 2 #{period_name}s"
        lookback_example = "L#{(code == "D") ? "7" : "4"}#{code} - in the prior #{(code == "D") ? "7" : "4"} #{period_name}s"
        calendar_example = "C1#{code} - this calendar #{period_name}"

        [base_example, lookback_example, calendar_example]
      end
    end

    def initialize(notation, parser: Parser.new(notation))
      @notation = notation
      @parser = parser
      validate_period

      return if @parser.valid?

      raise InvalidInput, "'#{notation}' is not a valid input"
    end

    attr_reader :parser

    delegate [:activated_notation, :volume, :from, :from_date, :time_span, :period,
      :humanized_period, :period_key, :active?] => :@parser
    delegate [:kind, :recurring?, :volume_only?, :valid_periods] => "self.class"
    delegate [:period_count, :duration] => :time_span
    delegate [:calendar?, :dormant?, :end_of?, :lookback?, :volume_only?,
      :within?] => :kind_inquiry

    def kind_inquiry = ActiveSupport::StringInquirer.new(kind.to_s)

    def validate_period
      return if valid_periods.empty?

      self.class.validate_period(period_key)
    end

    # Return the cycle representation as a notation string
    def notation = self.class.notation(to_h)

    # Cycles are considered equal if their hash representations are equal
    def ==(other) = to_h == other.to_h

    # Return the most recent completion date from the supplied array of dates
    def last_completed(dates) = dates.compact.map(&:to_date).max

    def extend_period(_ = nil) = self

    # From the supplied anchor date, are there enough in-window completions to
    # satisfy the cycle?
    #
    # @return [Boolean] true if the cycle is satisfied, false otherwise
    def satisfied_by?(completion_dates, anchor: Date.current)
      covered_dates(completion_dates, anchor:).size >= volume
    end

    def considered_dates(completion_dates, anchor: Date.current)
      covered_dates(completion_dates, anchor:).max_by(volume) { it }
    end

    def covered_dates(dates, anchor: Date.current)
      dates.select do |date|
        cover?(date, anchor:)
      end
    end

    def cover?(date, anchor: Date.current)
      range(anchor).cover?(date)
    end

    def range(anchor) = start_date(anchor)..final_date(anchor)

    def humanized_span = [period_count, humanized_period].join(" ")

    # Return the final date of the cycle
    def final_date(_anchor) = nil

    def expiration_of(_completion_dates, anchor: Date.current) = nil

    def volume_to_delay_expiration(_completion_dates, anchor:) = 0

    def to_h
      {
        kind:,
        volume:,
        period:,
        period_count:,
        **from_data
      }
    end

    def from_data
      return {} unless from

      {from: from}
    end

    def as_json(...) = notation
  end
end
