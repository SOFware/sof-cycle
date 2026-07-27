# frozen_string_literal: true

module SOF
  class Cycle
    # This class is not intended to be referenced directly.
    # This is an internal implementation of Cycle behavior.
    class TimeSpan
      extend Forwardable

      # TimeSpan objects map Cycle notations to behaviors for their periods
      #
      # For example:
      #   'M' => TimeSpan::DatePeriod::Month
      #   'Y' => TimeSpan::DatePeriod::Year
      # Read each DatePeriod subclass for more information.
      #
      class InvalidPeriod < StandardError; end

      # The set of classes measuring a period of time. Registration is
      # explicit — a class joins by declaring what it measures, not by
      # subclassing — which is what removes the inherited hook and lets the
      # parser build its period alternation from what is registered.
      #
      # Internal, like DatePeriod itself: periods are not an extension point.
      # Reach it through TimeSpan.period_registry.
      class PeriodRegistry
        def self.instance = @instance ||= new

        def initialize
          @period_classes = []
          @code_pattern = nil
        end

        # Add a period class, displacing any already measuring the same period
        # or claiming the same code, so an application can replace a built-in as
        # well as add to it. Returns the class.
        def register(period_class)
          displaced = @period_classes.reject { |klass| klass.equal?(period_class) }
            .select { |klass| conflicts?(klass, period_class) }
          @period_classes -= displaced
          @period_classes << period_class unless @period_classes.include?(period_class)
          @code_pattern = nil
          period_class
        end

        def unregister(period_class)
          @period_classes.delete(period_class)
          @code_pattern = nil
          period_class
        end

        def period_classes = @period_classes.dup

        # The class whose notation code this is, e.g. "M". Case-insensitive,
        # since a notation may be written either way. Nil when unrecognised —
        # DatePeriod.for falls back to its own default.
        def for_code(code)
          return if code.nil?

          normalized = code.to_s.upcase
          @period_classes.find { |klass| klass.code == normalized }
        end

        # The class measuring this period, e.g. :month. Nil when unrecognised.
        def for_period(period)
          @period_classes.find { |klass| klass.period.to_s == period.to_s }
        end

        # Registered codes, longest first so a longer code is never shadowed by
        # its own prefix.
        def codes
          @period_classes.filter_map(&:code).uniq.sort_by { |code| [-code.length, code] }
        end

        # The alternation the parser splices in for the period key. Rebuilt
        # whenever a class registers.
        def code_pattern
          @code_pattern ||= codes.map { Regexp.escape(it) }.join("|")
        end

        private

        def conflicts?(existing, incoming)
          return true if existing.period == incoming.period
          return false if incoming.code.nil?

          existing.code == incoming.code
        end
      end

      class << self
        # Return a time_span for the given count and period
        def for(count, period)
          case count.to_i
          when 0
            TimeSpanNothing
          when 1
            TimeSpanOne
          else
            self
          end.new(count, period)
        end

        # Return a notation string from a hash
        def notation(hash)
          return unless hash.key?(:period) && hash[:period].present?

          [
            hash.fetch(:period_count) { 1 },
            notation_id_from_name(hash[:period])
          ].compact.join
        end

        # The registry of period classes, owned by DatePeriod. Exposed here
        # because DatePeriod is a private constant, so callers outside cannot
        # name it — the parser needs the code alternation to build its pattern.
        def period_registry = PeriodRegistry.instance

        # Return the notation character for the given period name
        def notation_id_from_name(name)
          period_registry.for_period(name)&.code ||
            raise(InvalidPeriod, "'#{name}' is not a valid period")
        end
      end

      def notation
        [period_count, code].join
      end

      # Class used to calculate the windows of time so that
      # a TimeSpan object will know the correct end of year,
      # quarter, etc.
      class DatePeriod
        extend Forwardable

        class << self
          def for(count, period_notation)
            @cached_periods ||= {}
            @cached_periods[period_notation] ||= {}
            @cached_periods[period_notation][count] ||= (for_notation(period_notation) || self).new(count)
            @cached_periods[period_notation][count]
          end

          def for_notation(notation) = registry.for_code(notation)

          def types = registry.period_classes

          def registry = TimeSpan.period_registry

          # Declare the period this class measures, and register it.
          #
          # As with Cycle.handles, registration follows from declaring, so
          # subclassing DatePeriod on its own registers nothing, and an
          # application can add a period of its own — its code is recognised
          # because the parser builds that alternation from the registry.
          #
          # @param period [Symbol] the period measured, e.g. :month
          # @param code [String] the notation character, e.g. "M"
          # @param interval [String] the plural name used in descriptions
          #
          # @example
          #   class Fortnight < DatePeriod
          #     measures :fortnight, code: "N", interval: "fortnights"
          #     def duration = (count * 2).weeks
          #   end
          def measures(period, code:, interval:)
            @period = period
            @code = code
            @interval = interval
            registry.register(self)
          end

          @period = nil
          @code = nil
          @interval = nil
          attr_reader :period, :code, :interval
        end

        delegate [:period, :code, :interval] => "self.class"

        def initialize(count)
          @count = count
          @end_date = {}
          @begin_date = {}
        end
        attr_reader :count

        def end_date(date)
          @end_date[date] ||= date + duration
        end

        def begin_date(date)
          @begin_date[date] ||= date - duration
        end

        def duration = count.send(period)

        def end_of_period(_) = nil

        def humanized_period
          return period if count == 1

          "#{period}s"
        end

        class Year < self
          measures :year, code: "Y", interval: "years"

          def end_of_period(date)
            date.end_of_year
          end

          def beginning_of_period(date)
            date.beginning_of_year
          end
        end

        class Quarter < self
          measures :quarter, code: "Q", interval: "quarters"

          def duration
            (count * 3).months
          end

          def end_of_period(date)
            date.end_of_quarter
          end

          def beginning_of_period(date)
            date.beginning_of_quarter
          end
        end

        class Month < self
          measures :month, code: "M", interval: "months"

          def end_of_period(date)
            date.end_of_month
          end

          def beginning_of_period(date)
            date.beginning_of_month
          end
        end

        class Week < self
          measures :week, code: "W", interval: "weeks"

          def end_of_period(date)
            date.end_of_week
          end

          def beginning_of_period(date)
            date.beginning_of_week
          end
        end

        class Day < self
          measures :day, code: "D", interval: "days"

          def end_of_period(date)
            date
          end

          def beginning_of_period(date)
            date
          end
        end
      end
      private_constant :DatePeriod, :PeriodRegistry

      def initialize(count, period_id)
        @count = Integer(count, exception: false)
        @window = DatePeriod.for(period_count, period_id)
      end
      attr_reader :window

      delegate [:end_date, :begin_date, :code] => :window

      def end_date_of_period(date)
        window.end_of_period(date)
      end

      def begin_date_of_period(date)
        window.beginning_of_period(date)
      end

      # Integer value for the period count or nil
      def period_count
        @count
      end

      delegate [:period, :duration, :interval, :humanized_period] => :window

      # Return a date according to the rules of the time_span
      def final_date(date)
        return unless period

        window.end_date(date.to_date)
      end

      def to_h
        {
          period:,
          period_count:
        }
      end

      class TimeSpanNothing < self
      end

      class TimeSpanOne < self
        def interval = humanized_period
      end
    end
  end
end
