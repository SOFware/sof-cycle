# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

module SOF
  RSpec.describe Cycles::VolumeOnly, type: :value do
    subject(:cycle) { Cycle.for(notation) }

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

    it_behaves_like "#kind returns", :volume_only
    it_behaves_like "#valid_periods are", %w[]
    it_behaves_like "#to_s returns", "2x total"
    it_behaves_like "#volume returns the volume"
    it_behaves_like "#notation returns the notation"
    it_behaves_like "#as_json returns the notation"
    it_behaves_like "it computes #final_date(given)",
      given: "2003-03-08", returns: nil
    it_behaves_like "last_completed is", :recent_date
    it_behaves_like "it cannot be extended"

    describe "#recurring?" do
      it "does not repeat" do
        expect(cycle).not_to be_recurring
      end
    end

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

    describe ".validate_period" do
      it "raises an error if a period is provided" do
        expect {
          described_class.validate_period("D")
        }.to raise_error(Cycle::InvalidPeriod, /Invalid period value of 'D' provided/)
      end

      it "does not raise an error if period is nil" do
        expect { described_class.validate_period(nil) }.not_to raise_error
      end
    end

    describe "#satisfied_by?(completed_dates, anchor:)" do
      context "when the completions--judged from the anchor--satisfy the cycle" do
        it "returns true" do
          expect(cycle).to be_satisfied_by(completed_dates, anchor:)
        end
      end

      context "when the completions currently do not satisfy the cycle" do
        let(:notation) { "V5L180D" }

        it "returns false" do
          expect(cycle).not_to be_satisfied_by(completed_dates, anchor:)
        end
      end

      context "when there are no completions" do
        let(:completed_dates) { [] }

        it "returns false" do
          expect(cycle).not_to be_satisfied_by(completed_dates, anchor:)
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
