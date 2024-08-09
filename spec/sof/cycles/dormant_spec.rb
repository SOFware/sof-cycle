# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

module SOF
  RSpec.describe Cycles::Dormant, type: :value do
    subject(:within_cycle) { Cycle.for(within_notation) }

    let(:within_notation) { "V2W180D" }

    let(:end_of_cycle) { Cycle.for(end_of_notation) }
    let(:end_of_notation) { "V2E18M" }

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

    it_behaves_like "#kind returns", :dormant

    describe "#recurring?" do
      it "does not repeat" do
        expect(within_cycle).not_to be_recurring
      end
    end

    describe "#kind & #kind?" do
      it "returns the correct kind" do
        expect(within_cycle.kind).to eq(:dormant)
        expect(within_cycle).to be_dormant
      end
    end

    describe "#activated_notation" do
      it "appends the from data to the notation" do
        aggregate_failures do
          expect(within_cycle.activated_notation("2024-06-09"))
            .to eq("#{within_notation}F2024-06-09")
          expect(end_of_cycle.activated_notation("2024-06-09"))
            .to eq("#{end_of_notation}F2024-06-09")
        end
      end

      it "appends a Date even when supplied a Time" do
        time = "2024-06-09".to_time
        aggregate_failures do
          expect(within_cycle.activated_notation(time))
            .to eq("#{within_notation}F2024-06-09")
          expect(end_of_cycle.activated_notation(time))
            .to eq("#{end_of_notation}F2024-06-09")
        end
      end
    end

    describe "#covered_dates" do
      it "returns an empty array" do
        aggregate_failures do
          expect(within_cycle.covered_dates(completed_dates, anchor:)).to be_empty
          expect(end_of_cycle.covered_dates(completed_dates, anchor:)).to be_empty
        end
      end
    end

    describe "#satisfied_by?(completed_dates, anchor:)" do
      it "always returns false" do
        aggregate_failures do
          expect(within_cycle).not_to be_satisfied_by(completed_dates, anchor: 5.years.ago)
          expect(within_cycle).not_to be_satisfied_by(completed_dates, anchor:)
          expect(within_cycle).not_to be_satisfied_by([], anchor:)
          expect(within_cycle).not_to be_satisfied_by(completed_dates, anchor: 5.years.from_now)

          expect(end_of_cycle).not_to be_satisfied_by(completed_dates, anchor: 5.years.ago)
          expect(end_of_cycle).not_to be_satisfied_by(completed_dates, anchor:)
          expect(end_of_cycle).not_to be_satisfied_by([], anchor:)
          expect(end_of_cycle).not_to be_satisfied_by(completed_dates, anchor: 5.years.from_now)
        end
      end
    end

    describe "#expiration_of(completion_dates)" do
      it "always returns nil" do
        aggregate_failures do
          expect(within_cycle.expiration_of(completed_dates)).to be_nil
          expect(within_cycle.expiration_of([])).to be_nil

          expect(end_of_cycle.expiration_of(completed_dates)).to be_nil
          expect(end_of_cycle.expiration_of([])).to be_nil
        end
      end
    end

    describe "#volume" do
      it "returns the volume specified by the notation" do
        aggregate_failures do
          expect(within_cycle.volume).to eq(2)
          expect(end_of_cycle.volume).to eq(2)
        end
      end
    end

    describe "#notation" do
      it "returns the string representation of itself" do
        aggregate_failures do
          expect(within_cycle.notation).to eq(within_notation)
          expect(end_of_cycle.notation).to eq(end_of_notation)
        end
      end
    end
  end
end
