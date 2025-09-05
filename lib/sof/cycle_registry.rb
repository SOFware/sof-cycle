require "singleton"
require "concurrent/set"

module SOF
  class CycleRegistry
    include Singleton

    def register(cycle_class)
      cycle_classes << cycle_class
    end

    def cycle_classes
      @cycle_classes ||= Concurrent::Set.new
    end

    def handling(kind)
      cycle_classes.find { |klass| klass.respond_to?(:handles?) && klass.handles?(kind) } || raise(Cycle::InvalidKind, "':#{kind}' is not a valid kind of Cycle")
    end
  end
end
