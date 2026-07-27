# frozen_string_literal: true

require "spec_helper"

module SOF
  # What an application gets: declare a class, and its notation parses. No
  # reopening of this gem, no patching of the parser's pattern.
  RSpec.describe "declaring a cycle kind from an application", type: :value do
    # Registration is global, so every example puts the registry back.
    around do |example|
      before = Cycle.registry.cycle_classes
      example.run
      (Cycle.registry.cycle_classes - before).each { Cycle.registry.unregister(it) }
      before.each { Cycle.registry.register(it) }
    end

    describe "adding a kind of its own" do
      let!(:fortnightly) do
        Class.new(Cycle) do
          handles :fortnightly, notation: "X", periods: %w[D W M]

          def self.name = "Fortnightly"
          def self.recurring? = true
          def self.description = "Fortnightly"
          def self.examples = ["V1X2W"]
        end
      end

      it "parses its notation" do
        expect(Cycle.for("V1X2W")).to be_a(fortnightly)
      end

      it "reads the volume and period from the notation" do
        cycle = Cycle.for("V3X2W")

        expect(cycle.volume).to eq(3)
        expect(cycle.kind).to eq(:fortnightly)
        expect(cycle.period_count).to eq(2)
      end

      it "is reachable by kind and by notation id" do
        expect(Cycle.class_for_kind(:fortnightly)).to eq(fortnightly)
        expect(Cycle.class_for_notation_id("X")).to eq(fortnightly)
      end

      it "validates against the periods it declared" do
        expect { Cycle.for("V1X2Q") }.to raise_error(Cycle::InvalidPeriod)
      end

      it "appears in the legend" do
        expect(Cycle.legend["kind"]).to include("X")
      end

      it "leaves the built-in kinds working" do
        expect(Cycle.for("V1L30D")).to be_a(Cycles::Lookback)
        expect(Cycle.for("V1LE6M")).to be_a(Cycles::LookbackEndOf)
      end
    end

    describe "overriding a built-in kind" do
      let!(:custom_lookback) do
        Class.new(Cycles::Lookback) do
          handles :lookback, notation: "L", periods: %w[D W M Y]

          def self.name = "CustomLookback"
          def self.description = "Custom"
          def self.examples = ["V1L30D"]
          def to_s = "custom lookback"
        end
      end

      it "takes over the notation from the built-in class" do
        expect(Cycle.for("V1L30D")).to be_a(custom_lookback)
        expect(Cycle.for("V1L30D").to_s).to eq("custom lookback")
      end

      it "displaces the built-in rather than sitting alongside it" do
        expect(Cycle.registry.cycle_classes).not_to include(Cycles::Lookback)
      end

      it "does not disturb the kind whose notation merely shares a prefix" do
        expect(Cycle.for("V1LE6M")).to be_a(Cycles::LookbackEndOf)
      end
    end

    # The parser compiles its pattern once and reuses it, so a kind declared
    # after parsing has already begun — an initializer running after first
    # use — only works if that cache is keyed to what is registered.
    describe "declaring a kind after parsing has already happened" do
      it "recognises the new notation anyway" do
        Cycle.for("V1L30D") # compile the pattern with only the built-ins

        Class.new(Cycle) do
          handles :late, notation: "Z", periods: %w[D]
          def self.name = "Late"
          def self.recurring? = true
        end

        expect(Cycle.for("V1Z5D").kind).to eq(:late)
      end

      it "stops recognising a notation once its class is unregistered" do
        late = Class.new(Cycle) do
          handles :late, notation: "Z", periods: %w[D]
          def self.name = "Late"
          def self.recurring? = true
        end
        expect(Cycle.for("V1Z5D").kind).to eq(:late)

        Cycle.registry.unregister(late)

        expect { Cycle.for("V1Z5D") }.to raise_error(Cycle::InvalidInput)
      end
    end

    # Inheriting is the easy path, not a requirement: Cycle.for asks the
    # registry for a class and builds it, so anything answering the same
    # questions can stand in.
    describe "registering a class that does not inherit from Cycle" do
      let!(:standalone) do
        Class.new do
          def self.name = "Standalone"
          def self.kind = :standalone
          def self.notation_id = "S"
          def self.valid_periods = %w[D W M]
          def self.volume_only? = false
          def self.handles?(sym) = sym.to_s == "standalone"
          def self.dormant_capable? = false
          def self.recurring? = true
          def self.description = "Standalone"
          def self.examples = ["V1S3D"]
          def self.validate_period(_) = nil

          def initialize(notation, parser:)
            @notation = notation
            @parser = parser
          end

          def to_s = "standalone cycle"
        end.tap { Cycle.register(it) }
      end

      it "parses its notation and builds the registered class" do
        expect(Cycle.for("V1S3D")).to be_a(standalone)
      end

      it "is reachable by kind" do
        expect(Cycle.class_for_kind(:standalone)).to eq(standalone)
      end

      it "is dropped again by unregister" do
        Cycle.unregister(standalone)

        expect { Cycle.for("V1S3D") }.to raise_error(Cycle::InvalidInput)
      end
    end

    describe "subclassing without declaring" do
      it "registers nothing, so an abstract subclass is not a handler" do
        abstract = Class.new(Cycle) { def self.name = "Abstract" }

        expect(Cycle.registry.cycle_classes).not_to include(abstract)
      end
    end
  end
end
