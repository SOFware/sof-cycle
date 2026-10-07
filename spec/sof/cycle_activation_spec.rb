# frozen_string_literal: true

require "spec_helper"

module SOF
  RSpec.describe Cycle, "#activated_by", type: :value do
    describe "a dormant cycle" do
      it "anchors an EndOf on the date" do
        activated = Cycle.for("V1E24M").activated_by(Date.new(2025, 4, 17))

        expect(activated.notation).to eq("V1E24MF2025-04-17")
        expect(activated.final_date).to eq(Date.new(2027, 4, 30))
        expect(activated).not_to be_dormant
      end

      it "anchors an Interval on the date" do
        activated = Cycle.for("V1I24M").activated_by(Date.new(2026, 3, 31))

        expect(activated.notation).to eq("V1I24MF2026-03-31")
        expect(activated.final_date).to eq(Date.new(2028, 3, 31))
      end

      it "anchors a Within on the date" do
        activated = Cycle.for("V2W3D").activated_by(Date.new(2026, 1, 1))

        expect(activated.notation).to eq("V2W3DF2026-01-01")
      end

      it "anchors on the date of a Time" do
        activated = Cycle.for("V1E24M").activated_by(Time.parse("2025-04-17 13:45"))

        expect(activated.notation).to eq("V1E24MF2025-04-17")
      end

      it "anchors an un-anchored cycle built without the Dormant wrapper" do
        activated = Cycles::EndOf.new("V1E18M").activated_by(Date.new(2026, 2, 1))

        expect(activated.notation).to eq("V1E18MF2026-02-01")
      end
    end

    describe "cycles that are not activated" do
      it "leaves an active cycle alone — it is already anchored" do
        cycle = Cycle.for("V1E24MF2025-04-17")

        expect(cycle.activated_by(Date.new(2026, 1, 9))).to eq(cycle)
      end

      it "leaves a Lookback alone — its window already slides" do
        cycle = Cycle.for("V1L180D")

        expect(cycle.activated_by(Date.new(2026, 6, 1)).notation).to eq("V1L180D")
      end

      it "leaves a LookbackEndOf alone" do
        cycle = Cycle.for("V1LE6M")

        expect(cycle.activated_by(Date.new(2026, 6, 1)).notation).to eq("V1LE6M")
      end

      it "leaves a Calendar cycle alone — its window is fixed to the calendar" do
        cycle = Cycle.for("V1C1Y")

        expect(cycle.activated_by(Date.new(2026, 6, 1)).notation).to eq("V1C1Y")
      end

      it "leaves a volume-only cycle alone — it has no window" do
        cycle = Cycle.for("V2")

        expect(cycle.activated_by(Date.new(2026, 6, 1)).notation).to eq("V2")
      end
    end
  end
end
