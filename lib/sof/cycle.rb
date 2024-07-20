# frozen_string_literal: true

require_relative "parser"

module SOF
  class Cycle
    extend Forwardable
    class InvalidInput < StandardError; end

    class InvalidPeriod < InvalidInput; end

    class InvalidKind < InvalidInput; end

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
    delegate [:kind, :volume_only?, :valid_periods] => "self.class"
    delegate [:period_count, :duration] => :time_span

    # Turn a cycle or notation string into a hash
    def self.dump(cycle_or_string)
      if cycle_or_string.is_a? Cycle
        cycle_or_string
      else
        Cycle.for(cycle_or_string)
      end.to_h
    end

    # Return a Cycle object from a hash
    def self.load(hash)
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
    def self.notation(hash)
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
    def self.for(notation)
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
    def self.class_for_notation_id(notation_id)
      cycle_handlers.find do |klass|
        klass.notation_id == notation_id
      end || raise(InvalidKind, "'#{notation_id}' is not a valid kind of #{name}")
    end

    # Return the class handling the kind
    #
    # @param sym [Symbol] symbol matching the kind of Cycle class
    # @example
    #   class_for_kind(:lookback)
    def self.class_for_kind(sym)
      Cycle.cycle_handlers.find do |klass|
        klass.handles?(sym)
      end || raise(InvalidKind, "':#{sym}' is not a valid kind of Cycle")
    end

    def self.cycle_handlers = @cycle_handlers ||= Set.new

    def self.inherited(klass) = cycle_handlers << klass

    def self.handles?(sym)
      sym && kind == sym.to_sym
    end

    @volume_only = false
    @notation_id = nil
    @kind = nil
    @valid_periods = []

    def self.volume_only? = @volume_only

    class << self
      attr_reader :notation_id, :kind, :valid_periods
    end

    # Raises an error if the given period isn't in the list of valid periods.
    #
    # @param period [String] period matching the class valid periods
    # @raise [InvalidPeriod]
    def self.validate_period(period)
      raise InvalidPeriod, <<~ERR.squish unless valid_periods.include?(period)
        Invalid period value of '#{period}' provided. Valid periods are:
        #{valid_periods.join(", ")}
      ERR
    end

    def validate_period
      return if valid_periods.empty?

      self.class.validate_period(period_key)
    end

    # Return the cycle representation as a notation string
    def notation = self.class.notation(to_h)

    # Cycles are considered equal if their hash representations are equal
    def ==(other) = to_h == other.to_h

    # From the supplied anchor date, are there enough in-window completions to
    # satisfy the cycle?
    #
    # @return [Boolean] true if the cycle is satisfied, false otherwise
    def satisfied_by?(completion_dates, anchor: Date.current)
      covered_dates(completion_dates, anchor:).size >= volume
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

    class Lookback < self
      @volume_only = false
      @notation_id = "L"
      @kind = :lookback
      @valid_periods = %w[D W M Y]

      def to_s = "#{volume}x in the prior #{period_count} #{humanized_period}"

      def volume_to_delay_expiration(completion_dates, anchor:)
        oldest_relevant_completion = completion_dates.min
        [completion_dates.count(oldest_relevant_completion), volume].min
      end

      # "Absent further completions, you go red on this date"
      # @return [Date, nil] the date on which the cycle will expire given the
      #   provided completion dates. Returns nil if the cycle is already unsatisfied.
      def expiration_of(completion_dates)
        anchor = completion_dates.max_by(volume) { _1 }.min
        return unless satisfied_by?(completion_dates, anchor:)

        window_end anchor
      end

      def final_date(anchor)
        return if anchor.nil?

        time_span.end_date(anchor.to_date)
      end
      alias_method :window_end, :final_date

      def start_date(anchor)
        time_span.begin_date(anchor.to_date)
      end
      alias_method :window_start, :start_date
    end

    class Calendar < self
      @volume_only = false
      @notation_id = "C"
      @kind = :calendar
      @valid_periods = %w[M Q Y]

      class << self
        def frame_of_reference = "total"
      end

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
