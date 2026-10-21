# frozen_string_literal: true

require "spec_helper"

module SOF
  RSpec.describe Cycle, "#in_force_by", type: :value do
    let(:dates) { [Date.new(2026, 3, 20), Date.new(2026, 5, 2)] }

    def in_force(notation, dates) = Cycle.for(notation).in_force_by(dates)

    it "holds a dormant cycle short of its volume" do
      held = in_force("V3E12M", dates)

      expect(held.notation).to eq("V3E12M")
      expect(held).to be_dormant
    end

    it "anchors a dormant cycle on the latest date once the volume is met" do
      expect(in_force("V2E12M", dates).notation).to eq("V2E12MF2026-05-02")
    end

    it "counts every act, two on one day included" do
      same_day = [Time.parse("2026-03-20 08:00"), Time.parse("2026-03-20 17:00")]

      expect(in_force("V2I6M", same_day).notation).to eq("V2I6MF2026-03-20")
    end

    it "anchors on the latest date whatever order they arrive in" do
      expect(in_force("V2I6M", dates.reverse).notation).to eq("V2I6MF2026-05-02")
    end

    it "resets an active cycle by the dates past its anchor" do
      expect(in_force("V1I6MF2026-03-20", dates).notation).to eq("V1I6MF2026-05-02")
    end

    it "resets an active cycle by two acts on one day, as reset_by does" do
      same_day = [Time.parse("2026-05-02 08:00"), Time.parse("2026-05-02 17:00")]
      cycle = Cycle.for("V2I6MF2026-03-20")

      expect(cycle.in_force_by(same_day).notation).to eq("V2I6MF2026-05-02")
      expect(cycle.in_force_by(same_day).notation).to eq(cycle.reset_by(same_day).notation)
    end

    it "leaves a lookback cycle as it is" do
      expect(in_force("V1L6M", dates).notation).to eq("V1L6M")
    end
  end
end
