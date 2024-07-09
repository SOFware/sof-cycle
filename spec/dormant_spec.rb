# frozen_string_literal: true

require "spec_helper"

module SOF
  RSpec.describe Cycle::Dormant, type: :value do
    let(:cycle) { Cycle.for(notation) }
    let(:notation) { "V2W180D" }
    let(:anchor) { "2020-08-01".to_date }
    let(:completed_dates) do
      [
        recent_date,
        middle_date,
        early_date,
        early_date,
        out_of_window_date
      ]
    end
    let(:recent_date) { anchor - 1.days }
    let(:middle_date) { anchor - 70.days }
    let(:early_date) { anchor - 150.days }
    let(:out_of_window_date) { anchor - 182.days }

    describe "#activated_notation" do
      it "appends the from data to the notation" do
        expect(cycle.activated_notation("2024-06-09")).to eq("V2W180DF2024-06-09")
      end

      it "appends a Date even when supplied a Time" do
        time = "2024-06-09".to_time
        expect(cycle.activated_notation(time)).to eq("V2W180DF2024-06-09")
      end
    end

    describe "#covered_dates" do
      it "returns an empty array" do
        expect(cycle.covered_dates(completed_dates, anchor:)).to be_empty
      end
    end

    describe "#satisfied_by?(completed_dates, anchor:)" do
      it "always returns false" do
        aggregate_failures do
          expect(cycle.satisfied_by?(completed_dates, anchor: 5.years.ago)).to eq false
          expect(cycle.satisfied_by?(completed_dates, anchor:)).to eq false
          expect(cycle.satisfied_by?([], anchor:)).to eq false
          expect(cycle.satisfied_by?(completed_dates, anchor: 5.years.from_now)).to eq false
        end
      end
    end

    describe "#expiration_of(completion_dates)" do
      it "always returns nil" do
        aggregate_failures do
          expect(cycle.expiration_of(completed_dates)).to be_nil
          expect(cycle.expiration_of([])).to be_nil
        end
      end
    end

    describe "#volume" do
      it "returns the volume specified by the notation" do
        expect(cycle.volume).to eq(2)
      end
    end

    describe "#notation" do
      it "returns the string representation of itself" do
        expect(cycle.notation).to eq(notation)
      end
    end
  end
end
