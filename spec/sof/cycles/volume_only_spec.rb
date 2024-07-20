# frozen_string_literal: true

require "spec_helper"

module SOF
  RSpec.describe Cycles::VolumeOnly, type: :value do
    let(:cycle) { Cycle.for(notation) }
    let(:notation) { "V2" }
    let(:completed_dates) do
      [
        recent_date,
        middle_date,
        early_date,
        early_date
      ]
    end
    let(:recent_date) { anchor - 1.days }
    let(:middle_date) { anchor - 70.days }
    let(:early_date) { anchor - 99.years }
    let(:anchor) { "2020-08-01".to_date }

    describe "#covered_dates" do
      it "given an anchor date, returns dates that fall within it's window" do
        expect(cycle.covered_dates(completed_dates, anchor:)).to eq([
          recent_date,
          middle_date,
          early_date,
          early_date
        ])
      end
    end

    describe "#satisfied_by?(completed_dates, anchor:)" do
      context "when the completions--judged from the anchor--satisfy the cycle" do
        it "returns true" do
          expect(cycle.satisfied_by?(completed_dates, anchor:)).to eq true
        end
      end

      context "when the completions currently do not satisfy the cycle" do
        let(:notation) { "V5L180D" }

        it "returns false" do
          expect(cycle.satisfied_by?(completed_dates, anchor:)).to eq false
        end
      end

      context "when there are no completions" do
        let(:completed_dates) { [] }

        it "returns false" do
          expect(cycle.satisfied_by?(completed_dates, anchor:)).to eq false
        end
      end
    end

    describe "#expiration_of(completion_dates)" do
      context "when the completions currently satisfy the cycle" do
        it "returns nil" do
          expect(cycle.expiration_of(completed_dates)).to be nil
        end
      end

      context "when the completions currently do not satisfy the cycle" do
        let(:notation) { "V5L180D" }

        it "returns nil" do
          expect(cycle.expiration_of(completed_dates)).to be_nil
        end
      end
    end
  end
end