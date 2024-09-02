# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

module SOF
  RSpec.describe Cycles::EndOf, type: :value do
    subject(:cycle) { Cycle.for(notation) }

    let(:notation) { "V2E18MF#{from_date}" }
    let(:anchor) { nil }

    let(:end_date) { (from_date + 17.months).end_of_month }
    let(:from_date) { "2020-01-01".to_date }

    let(:completed_dates) { [] }

    it_behaves_like "#kind returns", :end_of
    it_behaves_like "#valid_periods are", %w[W M Q Y]

    describe "#recurring?" do
      it "repeats" do
        expect(cycle).to be_recurring
      end
    end

    @end_date = ("2020-01-01".to_date + 17.months).end_of_month
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
      given: nil, returns: ("2020-01-01".to_date + 17.months).end_of_month

    describe "#last_completed" do
      context "with an activated cycle" do
        it_behaves_like "last_completed is", :from_date
      end

      context "with a dormant cycle" do
        let(:notation) { "V2E18M" }

        it "returns nil" do
          expect(cycle.last_completed).to be_nil
        end
      end
    end

    describe "#covered_dates" do
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
      let(:recent_date) { from_date + 17.months }
      let(:middle_date) { from_date + 2.months }
      let(:early_date) { from_date + 1.month }
      let(:too_early_date) { from_date - 1.day }
      let(:too_late_date) { end_date + 1.day }

      let(:anchor) { "2021-06-29".to_date }
      it "given an anchor date, returns dates that fall within it's window" do
        expect(cycle.covered_dates(completed_dates, anchor:)).to eq([
          recent_date,
          middle_date,
          early_date,
          early_date
        ])
      end
    end

    describe "#satisfied_by?(anchor:)" do
      context "when the anchor date is < the final date" do
        let(:anchor) { "2021-06-29".to_date }

        it "returns true" do
          expect(cycle).to be_satisfied_by(anchor:)
        end
      end

      context "when the anchor date is = the final date" do
        let(:anchor) { "2021-06-30".to_date }

        it "returns true" do
          expect(cycle).to be_satisfied_by(anchor:)
        end
      end

      context "when the anchor date is > the final date" do
        let(:anchor) { "2021-07-01".to_date }

        it "returns false" do
          expect(cycle).not_to be_satisfied_by(completed_dates, anchor:)
        end
      end
    end

    describe "#expiration_of(completion_dates)" do
      context "when the anchor date is < the final date" do
        let(:anchor) { "2021-06-29".to_date }

        it "returns the final date" do
          expect(cycle.expiration_of(anchor:)).to eq "2021-06-30".to_date
        end
      end

      context "when the anchor date = the final date" do
        let(:anchor) { "2021-06-30".to_date }

        it "returns the final date" do
          expect(cycle.expiration_of(anchor:)).to eq "2021-06-30".to_date
        end
      end

      context "when the anchor date > the final date" do
        let(:anchor) { "2021-07-31".to_date }

        it "returns the final date" do
          expect(cycle.expiration_of(anchor:)).to eq "2021-06-30".to_date
        end
      end
    end
  end
end
