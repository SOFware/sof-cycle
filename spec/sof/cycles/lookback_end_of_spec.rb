# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

module SOF
  RSpec.describe Cycles::LookbackEndOf, type: :value do
    subject(:cycle) { Cycle.for(notation) }

    let(:notation) { "V1LE24M" }

    # April 10, 2026 — used as "today" in anchor-based tests
    let(:anchor) { "2026-04-10".to_date }

    # April 9, 2024 — one day before the standard 24-month lookback window
    # but inside the beginning_of_month-rounded window
    let(:edge_completion) { "2024-04-09".to_date }

    # May 15, 2024 — clearly inside the 24-month window (no rounding needed)
    let(:inside_completion) { "2024-05-15".to_date }

    # March 31, 2024 — one day before the rounded window start (April 1, 2024),
    # proving the boundary is beginning_of_month(anchor - period), not further back
    let(:outside_completion) { "2024-03-31".to_date }

    it_behaves_like "#kind returns", :lookback_end_of
    it_behaves_like "#valid_periods are", %w[D W M Q Y]
    it_behaves_like "#to_s returns", "1x in the prior 24 months (end of period)"
    it_behaves_like "#volume returns the volume"
    it_behaves_like "#notation returns the notation"
    it_behaves_like "#as_json returns the notation"
    it_behaves_like "it cannot be extended"

    describe "#recurring?" do
      it "repeats" do
        expect(cycle).to be_recurring
      end
    end

    describe "#satisfied_by?(completion_dates, anchor:)" do
      context "when a completion is one day before the exact lookback boundary but within the start of the period" do
        # Standard L24M window from April 10, 2026 starts April 10, 2024.
        # LE24M rounds to April 1, 2024 — so April 9, 2024 qualifies.
        it "returns true" do
          expect(cycle).to be_satisfied_by([edge_completion], anchor:)
        end
      end

      context "when a completion is clearly inside the rounded window" do
        it "returns true" do
          expect(cycle).to be_satisfied_by([inside_completion], anchor:)
        end
      end

      context "when a completion is outside the window even after rounding" do
        it "returns false" do
          expect(cycle).not_to be_satisfied_by([outside_completion], anchor:)
        end
      end

      context "with volume > 1" do
        let(:notation) { "V2LE24M" }

        it "requires the minimum number of completions" do
          expect(cycle).not_to be_satisfied_by([edge_completion], anchor:)
          expect(cycle).to be_satisfied_by([edge_completion, inside_completion], anchor:)
        end
      end

      context "when there are no completions" do
        it "returns false" do
          expect(cycle).not_to be_satisfied_by([], anchor:)
        end
      end
    end

    describe "#expiration_of(completion_dates)" do
      context "when satisfied" do
        # anchor = edge_completion = April 9, 2024
        # April 9, 2024 + 24 months = April 9, 2026 → end_of_month = April 30, 2026
        it "returns the end of the period in which the window boundary falls" do
          expect(cycle.expiration_of([edge_completion])).to eq("2026-04-30".to_date)
        end
      end

      context "with a completion in the middle of a period" do
        # May 15, 2024 + 24 months = May 15, 2026 → end_of_month = May 31, 2026
        it "rounds to end of that period" do
          expect(cycle.expiration_of([inside_completion])).to eq("2026-05-31".to_date)
        end
      end

      context "when not satisfied" do
        it "returns nil" do
          expect(cycle.expiration_of([outside_completion])).to be_nil
        end
      end

      context "with volume > 1" do
        let(:notation) { "V2LE24M" }

        # Uses the oldest of the most recent 2 completions as the anchor.
        # edge_completion (April 9, 2024) is the older of the two → April 9, 2024 + 24 months = April 30, 2026
        it "uses the oldest of the most recent volume completions" do
          expect(cycle.expiration_of([inside_completion, edge_completion])).to eq("2026-04-30".to_date)
        end
      end
    end

    describe "#final_date(anchor)" do
      # April 10, 2026 + 24 months = April 10, 2028 → end_of_month = April 30, 2028
      it "returns anchor + period rounded to end of period" do
        expect(cycle.final_date("2026-04-10".to_date)).to eq("2028-04-30".to_date)
      end
    end

    describe "Cycle.for" do
      it "returns a LookbackEndOf instance for LE notation" do
        expect(Cycle.for("V1LE24M")).to be_a(Cycles::LookbackEndOf)
      end

      it "does not affect plain Lookback" do
        expect(Cycle.for("V1L24M")).to be_a(Cycles::Lookback)
      end
    end
  end
end
