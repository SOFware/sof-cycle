# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

module SOF
  RSpec.describe Cycles::EndOf, type: :value do
    subject(:cycle) { Cycle.for(notation) }

    let(:notation) { "V2E18MF#{from_date}" }
    let(:anchor) { nil }

    let(:end_date) { (from_date.to_date + 18.months).end_of_month }
    let(:from_date) { "2020-01-01" }

    let(:completed_dates) do
      [
        recent_date,
        middle_date,
        early_date,
        early_date,
        too_early_date,
        too_late_date
      ]
    end
    let(:recent_date) { from_date.to_date + 17.months }
    let(:middle_date) { from_date.to_date + 2.months }
    let(:early_date) { from_date.to_date + 1.month }
    let(:too_early_date) { from_date.to_date - 1.day }
    let(:too_late_date) { end_date + 1.day }

    it_behaves_like "#kind returns", :end_of
    it_behaves_like "#valid_periods are", %w[W M Q Y]

    @end_date = ("2020-01-01".to_date + 18.months).end_of_month
    it_behaves_like "#to_s returns",
      "2x by #{@end_date.to_fs(:american)}"

    context "when the cycle is dormant" do
      before { allow(cycle).to receive(:dormant?).and_return(true) }

      it_behaves_like "#to_s returns",
        "2x by the last day of the 17th subsequent month"
    end
    it_behaves_like "#volume returns the volume"
    it_behaves_like "#notation returns the notation"
    it_behaves_like "#as_json returns the notation"
    it_behaves_like "it computes #final_date(given)",
      given: nil, returns: ("2020-01-01".to_date + 18.months).end_of_month

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
      context "when the completions--judged from the <from_date>--satisfy the cycle" do
        it "returns true" do
          expect(cycle).to be_satisfied_by(completed_dates, anchor:)
        end
      end

      context "when the completions are irrelevant to the given from_date" do
        let(:completed_dates) do
          [
            10.years.ago,
            Date.current,
            10.years.from_now
          ]
        end

        it "returns false" do
          expect(cycle).not_to be_satisfied_by(completed_dates, anchor:)
        end
      end

      context "when the completions currently do not satisfy the cycle" do
        let(:notation) { "V5E18M" }

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
        it "returns the date on which the completions will no longer satisfy the cycle" do
          expect(cycle.expiration_of(completed_dates)).to be nil
        end
      end

      context "when the completions currently do not satisfy the cycle" do
        let(:notation) { "V5E18M" }

        it "returns nil" do
          expect(cycle.expiration_of(completed_dates)).to be_nil
        end
      end
    end
  end
end
