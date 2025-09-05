require "singleton"

module SOF
  class CycleRegistry
    include Singleton

    def register(cycle_class)
      cycle_classes << cycle_class
    end

    def cycle_classes
      @cycle_classes ||= Set.new
    end

    def handling(kind)
      cycle_classes.find { |klass| klass.handles?(kind) } || raise(Cycle::InvalidKind, "':#{kind}' is not a valid kind of Cycle")
    end
  end
end
