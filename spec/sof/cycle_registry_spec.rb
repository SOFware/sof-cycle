# frozen_string_literal: true

require "spec_helper"

module SOF
  RSpec.describe CycleRegistry do
    subject(:registry) { described_class.new }

    # A stand-in handler. Registration takes anything answering the three
    # questions the registry asks, so specs need no real Cycle subclass.
    def handler(kind:, notation_id: nil)
      Class.new do
        define_singleton_method(:kind) { kind }
        define_singleton_method(:notation_id) { notation_id }
        define_singleton_method(:handles?) { |sym| kind.to_s == sym.to_s }
        define_singleton_method(:inspect) { "handler(#{kind})" }
      end
    end

    describe "#register" do
      it "adds a class and reports it as registered" do
        klass = handler(kind: :lookback, notation_id: "L")

        registry.register(klass)

        expect(registry.cycle_classes).to include(klass)
      end

      it "is idempotent — registering twice keeps one entry" do
        klass = handler(kind: :lookback, notation_id: "L")

        2.times { registry.register(klass) }

        expect(registry.cycle_classes.count(klass)).to eq(1)
      end

      it "returns the registered class so a declaration can chain" do
        klass = handler(kind: :lookback, notation_id: "L")

        expect(registry.register(klass)).to eq(klass)
      end
    end

    describe "#handling" do
      it "finds the class declaring that kind" do
        lookback = registry.register(handler(kind: :lookback, notation_id: "L"))
        registry.register(handler(kind: :calendar, notation_id: "C"))

        expect(registry.handling(:lookback)).to eq(lookback)
      end

      it "matches a string kind as well as a symbol" do
        lookback = registry.register(handler(kind: :lookback, notation_id: "L"))

        expect(registry.handling("lookback")).to eq(lookback)
      end

      it "raises InvalidKind for an unknown kind" do
        expect { registry.handling(:nonsense) }
          .to raise_error(Cycle::InvalidKind, /nonsense/)
      end
    end

    describe "#for_notation_id" do
      it "finds the class declaring that notation id" do
        lookback_end_of = registry.register(handler(kind: :lookback_end_of, notation_id: "LE"))
        registry.register(handler(kind: :lookback, notation_id: "L"))

        expect(registry.for_notation_id("LE")).to eq(lookback_end_of)
      end

      it "raises InvalidKind for an unknown notation id" do
        expect { registry.for_notation_id("Z") }
          .to raise_error(Cycle::InvalidKind, /Z/)
      end
    end

    describe "#notation_ids" do
      it "omits classes with no notation id, such as volume-only" do
        registry.register(handler(kind: :lookback, notation_id: "L"))
        registry.register(handler(kind: :volume_only, notation_id: nil))

        expect(registry.notation_ids).to eq(["L"])
      end

      it "orders longest first so a longer id is never shadowed by its prefix" do
        registry.register(handler(kind: :lookback, notation_id: "L"))
        registry.register(handler(kind: :lookback_end_of, notation_id: "LE"))

        expect(registry.notation_ids).to eq(%w[LE L])
      end
    end

    describe "#notation_pattern" do
      it "builds an alternation of the registered notation ids" do
        registry.register(handler(kind: :lookback, notation_id: "L"))
        registry.register(handler(kind: :lookback_end_of, notation_id: "LE"))

        expect(registry.notation_pattern).to eq("LE|L")
      end

      it "escapes ids so a regex-significant character cannot alter the pattern" do
        registry.register(handler(kind: :odd, notation_id: "A.B"))

        expect(registry.notation_pattern).to eq("A\\.B")
      end

      it "picks up a class registered after the pattern was first built" do
        registry.register(handler(kind: :lookback, notation_id: "L"))
        expect(registry.notation_pattern).to eq("L")

        registry.register(handler(kind: :custom, notation_id: "X"))

        expect(registry.notation_pattern).to eq("L|X")
      end
    end
  end
end
