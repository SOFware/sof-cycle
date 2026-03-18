# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

module SOF
  RSpec.describe Cycles::RepeatingWithin, type: :value do
    subject(:cycle) { Cycle.for(notation) }

    let(:notation) { "V1I24MF#{from_date}" }
    let(:anchor) { nil }

    let(:end_date) { from_date + 24.months }
    let(:from_date) { "2026-03-31".to_date }

    let(:completed_dates) { [] }

    it_behaves_like "#kind returns", :repeating_within
    it_behaves_like "#valid_periods are", %w[D W M Y]

    describe "#recurring?" do
      it "repeats" do
        expect(cycle).to be_recurring
      end
    end

    describe "inherits from Within" do
      it "is a Within" do
        expect(described_class).to be < Cycles::Within
      end

      it "computes final_date the same as Within" do
        within = Cycle.for("V1W24MF#{from_date}")
        expect(cycle.final_date).to eq within.final_date
      end

      it "computes start_date the same as Within" do
        within = Cycle.for("V1W24MF#{from_date}")
        expect(cycle.start_date).to eq within.start_date
      end
    end

    @from = "2026-03-31".to_date.to_fs(:american)
    it_behaves_like "#to_s returns",
      "1x every 24 months from #{@from}"

    context "when the cycle is dormant" do
      before { allow(cycle.parser).to receive(:dormant?).and_return(true) }

      it_behaves_like "#to_s returns",
        "1x every 24 months"
    end

    it_behaves_like "#volume returns the volume"
    it_behaves_like "#notation returns the notation"
    it_behaves_like "#as_json returns the notation"
    it_behaves_like "it computes #final_date(given)",
      given: nil, returns: "2026-03-31".to_date + 24.months
    it_behaves_like "it cannot be extended"

    describe "#last_completed" do
      context "with an activated cycle" do
        it_behaves_like "last_completed is", :from_date
      end

      context "with a dormant cycle" do
        let(:notation) { "V1I24M" }

        it "returns nil" do
          expect(cycle.last_completed).to be_nil
        end
      end
    end

    describe "#final_date" do
      it "returns from_date + period without end-of-month rounding" do
        expect(cycle.final_date).to eq "2028-03-31".to_date
      end

      context "with a mid-month from_date" do
        let(:from_date) { "2026-06-15".to_date }

        it "preserves the exact day" do
          expect(cycle.final_date).to eq "2028-06-15".to_date
        end
      end
    end

    describe "#covered_dates" do
      let(:completed_dates) do
        [
          within_window,
          just_before_end,
          too_early_date,
          too_late_date
        ]
      end
      let(:within_window) { from_date + 6.months }
      let(:just_before_end) { end_date - 1.day }
      let(:too_early_date) { from_date - 1.day }
      let(:too_late_date) { end_date + 1.day }

      let(:anchor) { from_date + 1.year }

      it "returns dates that fall within the window" do
        expect(cycle.covered_dates(completed_dates, anchor:)).to eq([
          within_window,
          just_before_end
        ])
      end
    end

    describe "#satisfied_by?(anchor:)" do
      context "when the anchor date is < the final date" do
        let(:anchor) { "2028-03-30".to_date }

        it "returns true" do
          expect(cycle).to be_satisfied_by(anchor:)
        end
      end

      context "when the anchor date is = the final date" do
        let(:anchor) { "2028-03-31".to_date }

        it "returns true" do
          expect(cycle).to be_satisfied_by(anchor:)
        end
      end

      context "when the anchor date is > the final date" do
        let(:anchor) { "2028-04-01".to_date }

        it "returns false" do
          expect(cycle).not_to be_satisfied_by(completed_dates, anchor:)
        end
      end
    end

    describe "#expiration_of" do
      it "returns the final date" do
        expect(cycle.expiration_of).to eq "2028-03-31".to_date
      end
    end

    describe "#reactivated_notation" do
      it "returns a new notation with the updated from_date" do
        new_notation = cycle.reactivated_notation("2028-03-15".to_date)
        expect(new_notation).to eq "V1I24MF2028-03-15"
      end

      it "is functionally identical to activated_notation" do
        date = "2028-06-01".to_date
        expect(cycle.reactivated_notation(date)).to eq cycle.activated_notation(date)
      end
    end

    describe "dormant behavior" do
      let(:notation) { "V1I24M" }

      it "is dormant without a from_date" do
        expect(cycle).to be_dormant
      end

      it "returns nil for final_date" do
        expect(cycle.final_date).to be_nil
      end

      it "returns nil for expiration_of" do
        expect(cycle.expiration_of).to be_nil
      end

      it "returns false for satisfied_by?" do
        expect(cycle).not_to be_satisfied_by(anchor: Date.current)
      end
    end

    describe "activation" do
      let(:notation) { "V1I24M" }

      it "can be activated with a date" do
        activated = Cycle.for(cycle.parser.activated_notation("2026-03-31".to_date))
        expect(activated.notation).to eq "V1I24MF2026-03-31"
        expect(activated).not_to be_dormant
      end
    end
  end
end
