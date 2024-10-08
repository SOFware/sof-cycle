# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

module SOF
  RSpec.describe Cycles::Calendar, type: :value do
    subject(:cycle) { Cycle.for(notation) }

    let(:notation) { "V2C1Y" }
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
    let(:out_of_window_date) { anchor - 11.months }
    let(:anchor) { "2020-08-01".to_date }

    it_behaves_like "#kind returns", :calendar
    it_behaves_like "#valid_periods are", %w[M Q Y]
    it_behaves_like "#to_s returns", "2x every 1 calendar year"
    it_behaves_like "#volume returns the volume"
    it_behaves_like "#notation returns the notation"
    it_behaves_like "#as_json returns the notation"
    it_behaves_like "it computes #final_date(given)",
      given: "1971-01-01", returns: "1971-12-31".to_date
    it_behaves_like "last_completed is", :recent_date
    it_behaves_like "it cannot be extended"

    describe "#recurring?" do
      it "repeats" do
        expect(cycle).to be_recurring
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

    describe "#satisfied_by?(completed_dates, anchor:)" do
      context "when the completions--judged from the anchor--satisfy the cycle" do
        it "returns true" do
          expect(cycle).to be_satisfied_by(completed_dates, anchor:)
        end
      end

      context "when the completions are irrelevant to the given anchor" do
        it "returns false" do
          expect(cycle).not_to be_satisfied_by(completed_dates, anchor: Date.current)
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
        it "returns the end of the _next_ calendar period" do
          expect(cycle.expiration_of(completed_dates)).to eq(
            (recent_date + 1.year).end_of_year
          )
        end
      end

      context "when the period is months" do
        let(:notation) { "V1C1M" }
        let(:completed_dates) { ["2020-01-15".to_date] }
        let(:anchor) { "2020-01-16".to_date }

        it "returns the end of the _next_ calendar period" do
          expect(cycle.expiration_of(completed_dates)).to eq(
            "2020-02-29".to_date
          )
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
