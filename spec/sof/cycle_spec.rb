# frozen_string_literal: true

require "spec_helper"

module SOF
  RSpec.describe Cycle, type: :value do
    describe ".notation" do
      it "returns a string notation for the given hash" do
        expect(
          described_class.notation(volume: 3, kind: :lookback, period: :day, period_count: 3)
        ).to eq("V3L3D")
      end

      it "assumes a volume of 1 when it is not provided" do
        expect(
          described_class.notation(kind: :calendar, period: :month, period_count: 2)
        ).to eq("V1C2M")
      end

      it "returns volume notation only, if there is no kind" do
        expect(
          described_class.notation(volume: 7, period: :month, period_count: 2)
        ).to eq("V7")
      end
    end

    describe ".load" do
      it "returns a Cycle object from a given hash" do
        data = {kind: :calendar, period: :month, period_count: 2}
        expect(described_class.load(data)).to be_a(Cycle)
      end

      it "allows mixed key types" do
        data = {"kind" => :calendar, :period => :month, "period_count" => 2}
        expect(described_class.load(data)).to be_a(Cycle)
      end

      it "raises an error when given an invalid period for the kind" do
        data = {"kind" => :calendar, :period => :xyz, "period_count" => 2}
        expect { described_class.load(data) }.to raise_error(Cycle::InvalidPeriod)
      end

      it "raises an error when given an invalid kind" do
        data = {"kind" => :wtf}
        expect { described_class.load(data) }.to raise_error(Cycle::InvalidKind)
      end
    end

    describe ".dump" do
      it "generates a hash from a Cycle object" do
        cycle = Cycle.for("V5C2M")
        expect(described_class.dump(cycle)).to eq({
          volume: 5,
          kind: :calendar,
          period_count: 2,
          period: :month
        })
      end

      it "generates a hash from a notation" do
        expect(described_class.dump("V5C2M")).to eq({
          volume: 5,
          kind: :calendar,
          period_count: 2,
          period: :month
        })
      end
    end

    describe ".for" do
      it "returns a Cycle object matching the notation" do
        aggregate_failures do
          expect(Cycle.for("V1")).to eq(Cycle.load({volume: 1}))
          expect(Cycle.for("V1C1Y")).to eq(Cycle.load({
            volume: 1,
            kind: :calendar,
            period_count: 1,
            period: :year
          }))
        end
      end

      it "raises an error with invalid kind and period combinations" do
        aggregate_failures do
          expect { Cycle.for("L1Q") }.to raise_error(
            Cycle::InvalidPeriod,
            /Invalid period value of 'Q' provided. Valid periods are: D, W, M, Y/
          )
          expect { Cycle.for("C1W") }.to raise_error(
            Cycle::InvalidPeriod,
            /Invalid period value of 'W' provided. Valid periods are: M, Q, Y/
          )
        end
      end

      it "returns the argument if it is already a Cycle" do
        cycle = Cycle.for("V1")
        expect(Cycle.for(cycle)).to eq(cycle)
      end
    end
  end
end
