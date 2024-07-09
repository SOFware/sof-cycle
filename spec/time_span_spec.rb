# frozen_string_literal: true

require "spec_helper"

module SOF
  RSpec.describe SOF::Cycle::TimeSpan, type: :value do
    describe ".notation" do
      it "accepts a hash and returns a string notation" do
        aggregate_failures do
          expect(described_class.notation(period: :day, period_count: 3)).to eq("3D")
          expect(described_class.notation(period: :month, period_count: 2)).to eq("2M")
          expect(described_class.notation(period: :quarter, period_count: 5)).to eq("5Q")
          expect(described_class.notation(period: :year, period_count: 2)).to eq("2Y")
        end
      end
    end

    describe ".for" do
      it "returns a TimeSpan object" do
        expect(described_class.for(1, "M")).to be_a(described_class)
      end

      it "accepts string counts" do
        expect(described_class.for("5", "M").period_count).to eq(5)
      end

      it "accepts lowercase periods" do
        expect(described_class.for(3, "m").period).to eq(:month)
      end
    end

    describe "#end_date_of_period" do
      it "is nil if there is no period" do
        expect(described_class.for("", "").end_date_of_period(Time.current)).to be_nil
      end

      it "for a year period returns a date at the end of the next calendar year" do
        span = described_class.for("1", "Y")
        expect(span.end_date_of_period("2022-01-15".to_date)).to eq Date.parse("2022-12-31")
      end

      it "for a month period returns a date 30 days later" do
        span = described_class.for("1", "m")
        expect(span.end_date_of_period("2022-01-15".to_date)).to eq Date.parse("2022-01-31")
      end

      it "for a week period returns a date a at the end of the week" do
        span = described_class.for("1", "w")
        expect(span.end_date_of_period("2022-01-15".to_date)).to eq Date.parse("2022-01-16")
      end

      it "for a day period returns a the same date" do
        span = described_class.for("1", "D")
        expect(span.end_date_of_period("2022-01-15".to_date)).to eq Date.parse("2022-01-15")
      end

      it "for a quarter period returns a date at the end of the next quarter" do
        span = described_class.for("1", "Q")
        expect(span.end_date_of_period("2022-01-15".to_date)).to eq Date.parse("2022-03-31")
      end
    end
  end
end
