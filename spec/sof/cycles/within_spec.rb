# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

module SOF
  RSpec.describe Cycles::Within, type: :value do
    subject(:cycle) { Cycle.for(notation) }

    let(:notation) { "V2W180DF#{from_date}" }
    let(:completed_dates) do
      [
        too_early,
        too_late,
        first_valid,
        last_valid
      ]
    end
    let(:too_late) { from_date + 181.days }
    let(:too_early) { from_date - 1.day }
    let(:first_valid) { from_date }
    let(:last_valid) { from_date + 180.days }
    let(:from_date) { "2020-08-01".to_date }

    let(:anchor) { "2999-08-01".to_date } # anchor never matters for this cycle

    it_behaves_like "#kind returns", :within
    it_behaves_like "#valid_periods are", %w[D W M Y]
    it_behaves_like "#to_s returns", "2x within 2020-08-01 - 2021-01-28"
    it_behaves_like "#volume returns the volume"
    it_behaves_like "#notation returns the notation"
    it_behaves_like "#as_json returns the notation"
    it_behaves_like "it computes #final_date(given)",
      given: "_", returns: ("2020-08-01".to_date + 180.days)
    it_behaves_like "last_completed is", :too_late

    describe "#recurring?" do
      it "does not repeat" do
        expect(cycle).not_to be_recurring
      end
    end

    describe "#start_date" do
      it "returns the <from_date>" do
        expect(cycle.start_date).to eq(from_date)
      end
    end

    describe "#to_s" do
      it "returns a string representation of the cycle" do
        range = [from_date, from_date + 180.days].map { |d| d.to_fs(:american) }.join(" - ")
        expect(cycle.to_s).to eq "2x within #{range}"
      end
    end

    describe "#covered_dates" do
      it "given an anchor date, returns dates that fall within it's window" do
        expect(cycle.covered_dates(completed_dates, anchor:)).to eq([
          first_valid,
          last_valid
        ])
      end
    end

    describe "#satisfied_by?(completed_dates, anchor:)" do
      context "when the completions--judged from the <from_date>--satisfy the cycle" do
        it "returns true" do
          expect(cycle).to be_satisfied_by(completed_dates, anchor:)
        end
      end

      context "when the completions currently do not satisfy the cycle" do
        let(:notation) { "V3W180D" }

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
