# frozen_string_literal: true

require "spec_helper"

module SOF
  # A recurring, dormant-capable window (E and I) restarts from the act that
  # satisfies it. Previously every consuming app had to do this itself.
  RSpec.describe Cycle, "#reset_by", type: :value do
    describe "an EndOf cycle" do
      subject(:cycle) { Cycle.for("V1E18MF2026-02-01") }

      it "re-anchors from the latest date past its anchor" do
        reset = cycle.reset_by([Date.new(2026, 6, 1), Date.new(2026, 9, 15)])

        expect(reset.notation).to eq("V1E18MF2026-09-15")
        expect(reset.final_date).to eq(Date.new(2028, 3, 31))
      end

      it "returns itself when no date resets it" do
        expect(cycle.reset_by([])).to eq(cycle)
      end

      it "ignores dates on or before the anchor so the window never moves backwards" do
        reset = cycle.reset_by([Date.new(2025, 12, 1), Date.new(2026, 2, 1)])

        expect(reset.notation).to eq("V1E18MF2026-02-01")
      end

      it "re-anchors from a date past the window, restoring a lapsed cycle" do
        reset = cycle.reset_by([Date.new(2029, 1, 1)])

        expect(reset).to be_satisfied_by([], anchor: Date.new(2029, 6, 1))
      end

      it "accepts times and nils among the dates" do
        reset = cycle.reset_by([nil, Time.parse("2026-06-01 13:45")])

        expect(reset.notation).to eq("V1E18MF2026-06-01")
      end
    end

    describe "an Interval cycle" do
      subject(:cycle) { Cycle.for("V1I24MF2026-03-31") }

      it "re-anchors from the completion date, as its notation promises" do
        reset = cycle.reset_by([Date.new(2027, 1, 10)])

        expect(reset.notation).to eq("V1I24MF2027-01-10")
        expect(reset.final_date).to eq(Date.new(2029, 1, 10))
      end
    end

    describe "cycles that do not reset" do
      it "leaves a dormant cycle alone — it has no anchor to move" do
        cycle = Cycle.for("V1E18M")

        expect(cycle.reset_by([Date.new(2026, 6, 1)])).to eq(cycle)
        expect(cycle).to be_dormant
      end

      it "leaves a Lookback alone — its window already slides" do
        cycle = Cycle.for("V1L180D")

        expect(cycle.reset_by([Date.new(2026, 6, 1)]).notation).to eq("V1L180D")
      end

      it "leaves a LookbackEndOf alone" do
        cycle = Cycle.for("V1LE6M")

        expect(cycle.reset_by([Date.new(2026, 6, 1)]).notation).to eq("V1LE6M")
      end

      it "leaves a Calendar cycle alone — its window is fixed to the calendar" do
        cycle = Cycle.for("V1C1Y")

        expect(cycle.reset_by([Date.new(2026, 6, 1)]).notation).to eq("V1C1Y")
      end

      it "leaves a Within alone — a one-shot window does not repeat" do
        cycle = Cycle.for("V2W3DF2026-01-01")

        expect(cycle.reset_by([Date.new(2026, 1, 2)]).notation).to eq("V2W3DF2026-01-01")
      end

      it "leaves a volume-only cycle alone — it has no window" do
        cycle = Cycle.for("V2")

        expect(cycle.reset_by([Date.new(2026, 6, 1)]).notation).to eq("V2")
      end

      # Cycle.for wraps an un-anchored cycle in Cycles::Dormant, but a handler
      # built directly skips that wrapper and still has no from date to move.
      it "leaves an un-anchored cycle alone when built without the Dormant wrapper" do
        cycle = Cycles::EndOf.new("V1E18M")

        expect(cycle.reset_by([Date.new(2026, 6, 1)])).to eq(cycle)
      end
    end
  end

  RSpec.describe Cycle, "#dormant_capable?", type: :value do
    # Reachable on every cycle, including the ones actually dormant — asking
    # the class breaks there, because a dormant cycle is a Cycles::Dormant.
    {
      "V1E18M" => true, "V1E18MF2026-02-01" => true,
      "V1I24M" => true, "V1I24MF2026-02-01" => true,
      "V2W3D" => true,
      "V1L180D" => false, "V1LE6M" => false, "V1C1Y" => false, "V2" => false
    }.each do |notation, expected|
      it "is #{expected} for #{notation}" do
        expect(Cycle.for(notation).dormant_capable?).to be(expected)
      end
    end
  end
end
