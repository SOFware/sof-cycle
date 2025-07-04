# frozen_string_literal: true

require "spec_helper"
require_relative "shared_examples"

module SOF
  RSpec.describe Cycles::Lookback, type: :value do
    subject(:cycle) { Cycle.for(notation) }

    let(:notation) { "V2L180D" }
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

    it_behaves_like "#kind returns", :lookback
    it_behaves_like "#valid_periods are", %w[D W M Y]
    it_behaves_like "#to_s returns", "2x in the prior 180 days"
    it_behaves_like "#volume returns the volume"
    it_behaves_like "#notation returns the notation"
    it_behaves_like "#as_json returns the notation"
    it_behaves_like "it computes #final_date(given)",
      given: "2003-03-08", returns: ("2003-03-08".to_date + 180.days)
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

    describe "#considered_dates" do
      let(:completed_dates) do
        [
          recent_date,
          middle_date,
          middle_date,
          early_date,
          early_date,
          out_of_window_date
        ]
      end
      let(:notation) { "V3L180D" }

      it "returns {volume} most recent of the #covered_dates" do
        expect(cycle.considered_dates(completed_dates, anchor:)).to eq([
          recent_date,
          middle_date,
          middle_date
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
        it "returns the date on which the completions will no longer satisfy the cycle" do
          expect(cycle.expiration_of(completed_dates)).to eq(middle_date + 180.days)
        end
      end

      context "when the completions currently do not satisfy the cycle" do
        let(:notation) { "V5L180D" }

        it "returns nil" do
          expect(cycle.expiration_of(completed_dates)).to be_nil
        end
      end
    end

    describe "#volume_to_delay_expiration(completed_dates, anchor:)" do
      let(:notation) { "V4L6M" }

      context "when the completions currently satisfy the cycle" do
        let(:completed_dates) do
          [
            anchor - 1.day,
            anchor - 5.months,
            anchor - 5.months,
            anchor - 5.months,
            anchor - 5.months,
            anchor - 1.year
          ]
        end

        it "returns the volume needed to delay expiration" do
          expect(cycle.volume_to_delay_expiration(completed_dates, anchor:)).to eq(3)
        end

        context "when the considered dates are < the covered_dates" do
          let(:completed_dates) do
            [
              anchor - 1.day,
              anchor - 3.months,
              anchor - 3.months,
              anchor - 3.months,
              anchor - 5.months,
              anchor - 5.months,
              anchor - 1.year
            ]
          end

          it "returns the volume needed to delay expiration" do
            # The expiration only considers the `anchor - 3.months` and more recent
            # completions, so how many new completions are needed to result in
            # a more recent oldest-of-considered-datex?
            expect(cycle.volume_to_delay_expiration(completed_dates, anchor:)).to eq(3)
          end
        end
      end

      context "when the completions currently do not satisfy the cycle" do
        let(:completed_dates) { Array.new(6, anchor - 1.year) }

        it "returns nil" do
          expect(cycle.volume_to_delay_expiration(completed_dates, anchor:)).to be_nil
        end
      end
    end
  end
end
