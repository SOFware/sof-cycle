# frozen_string_literal: true

module SOF
  class Cycle
    # The set of classes that handle cycle kinds.
    #
    # Registration is explicit — a class joins by declaring what it handles
    # (see Cycle.handles), not by subclassing. Inheriting from Cycle for any
    # other reason, such as a test double or an abstract intermediate, then
    # carries no hidden side effect.
    #
    # The registry is also what the parser reads to recognise notations, so an
    # application can add a kind of its own and have its notation parse without
    # reopening this gem.
    class Registry
      def self.instance = @instance ||= new

      def initialize
        @cycle_classes = []
        @notation_pattern = nil
      end

      # Add a handler, displacing any already handling the same kind or
      # notation id. That is what lets an application override a built-in
      # kind — declare a class handling :lookback and it takes over "L" —
      # as well as add one of its own. Re-registering the same class is a
      # no-op, so a reloaded file accumulates no duplicates.
      #
      # Returns the class, so a declaration can use the result.
      def register(cycle_class)
        displaced = @cycle_classes.reject { |klass| klass.equal?(cycle_class) }
          .select { |klass| conflicts?(klass, cycle_class) }
        @cycle_classes -= displaced
        @cycle_classes << cycle_class unless @cycle_classes.include?(cycle_class)
        @notation_pattern = nil
        cycle_class
      end

      # Drop a handler. Mainly for an application undoing an override, and for
      # tests that register a throwaway kind.
      def unregister(cycle_class)
        @cycle_classes.delete(cycle_class)
        @notation_pattern = nil
        cycle_class
      end

      def cycle_classes = @cycle_classes.dup

      # The class declaring `kind`.
      def handling(kind)
        @cycle_classes.find { |klass| klass.handles?(kind) } ||
          raise(InvalidKind, "':#{kind}' is not a valid kind of Cycle")
      end

      # The class declaring `notation_id` — the letter(s) that open a cycle's
      # notation, such as "L" or "LE".
      def for_notation_id(notation_id)
        @cycle_classes.find { |klass| klass.notation_id == notation_id } ||
          raise(InvalidKind, "'#{notation_id}' is not a valid kind of Cycle")
      end

      # Registered notation ids, longest first. A volume-only cycle has none,
      # so it contributes nothing to parse.
      def notation_ids
        @cycle_classes.filter_map(&:notation_id).uniq.sort_by { |id| [-id.length, id] }
      end

      # The alternation the parser splices into its pattern. Rebuilt whenever a
      # class registers, so a kind added at runtime is recognised from then on.
      def notation_pattern
        @notation_pattern ||= notation_ids.map { Regexp.escape(it) }.join("|")
      end

      private

      # Two handlers conflict when they answer to the same kind, or claim the
      # same notation id. A nil notation id claims nothing.
      def conflicts?(existing, incoming)
        return true if existing.kind == incoming.kind
        return false if incoming.notation_id.nil?

        existing.notation_id == incoming.notation_id
      end
    end
  end
end
