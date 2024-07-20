# frozen_string_literal: true

module SOF
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
        return unless hash.key?(:period)

        [
          hash.fetch(:period_count) { 1 },
          notation_id_from_name(hash[:period])
        ].compact.join
      end

      # Return the notation character for the given period name
      def notation_id_from_name(name)
        type = DatePeriod.types.find do |klass|
          klass.period.to_s == name.to_s
        end

        raise InvalidPeriod, "'#{name}' is not a valid period" unless type

        type.code
      end
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

        def for_notation(notation)
          types.find do |klass|
            klass.code == notation.to_s.upcase
          end
        end

        def types = @types ||= Set.new

        def inherited(klass)
          DatePeriod.types << klass
        end

        @period = nil
        @code = nil
        @interval = nil
        attr_reader :period, :code, :interval
      end

      delegate [:period, :code, :interval] => "self.class"

      def initialize(count)
        @count = count
      end
      attr_reader :count

      def end_date(date)
        @end_date ||= {}
        @end_date[date] ||= date + duration
      end

      def begin_date(date)
        @begin_date ||= {}
        @begin_date[date] ||= date - duration
      end

      def duration = count.send(period)

      def end_of_period(_) = nil

      def humanized_period
        return period if count == 1

        "#{period}s"
      end

      class Year < self
        @period = :year
        @code = "Y"
        @interval = "years"

        def end_of_period(date)
          date.end_of_year
        end

        def beginning_of_period(date)
          date.beginning_of_year
        end
      end

      class Quarter < self
        @period = :quarter
        @code = "Q"
        @interval = "quarters"

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
        @period = :month
        @code = "M"
        @interval = "months"

        def end_of_period(date)
          date.end_of_month
        end

        def beginning_of_period(date)
          date.beginning_of_month
        end
      end

      class Week < self
        @period = :week
        @code = "W"
        @interval = "weeks"

        def end_of_period(date)
          date.end_of_week
        end

        def beginning_of_period(date)
          date.beginning_of_week
        end
      end

      class Day < self
        @period = :day
        @code = "D"
        @interval = "days"

        def end_of_period(date)
          date
        end

        def beginning_of_period(date)
          date
        end
      end
    end
    private_constant :DatePeriod

    def initialize(count, period_id)
      @count = Integer(count, exception: false)
      @window = DatePeriod.for(period_count, period_id)
    end
    attr_reader :window

    delegate [:end_date, :begin_date] => :window

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
