# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SOF::Cycle.legend" do
  subject(:legend) { SOF::Cycle.legend }

  it "returns a hash" do
    expect(legend).to be_a(Hash)
  end

  it "includes all top-level categories" do
    expected_categories = %w[quantity kind period date]
    expect(legend.keys).to match_array(expected_categories)
  end

  describe "quantity section" do
    let(:quantity) { legend["quantity"] }

    it "includes volume notation" do
      expect(quantity).to have_key("V")
    end

    it "has appropriate description for volume" do
      expect(quantity["V"][:description]).to include("Volume")
      expect(quantity["V"][:description]).to include("number")
    end

    it "has valid examples for volume" do
      expect(quantity["V"][:examples]).to include("V1L1D - once in the prior 1 day")
      expect(quantity["V"][:examples]).to include("V3L3D - three times in the prior 3 days")
    end
  end

  describe "kind section" do
    let(:kind) { legend["kind"] }

    it "includes all cycle kinds" do
      # Should include at least L, C, W, E
      expect(kind.keys).to include("L", "C", "W", "E")
    end

    it "each kind has a description and examples" do
      kind.each do |key, value|
        expect(value).to have_key(:description), "#{key} is missing :description"
        expect(value).to have_key(:examples), "#{key} is missing :examples"
        expect(value[:description]).to be_a(String), "#{key} description should be a String"
        expect(value[:examples]).to be_an(Array), "#{key} examples should be an Array"
      end
    end

    describe "L (Lookback)" do
      let(:lookback_info) { kind["L"] }

      it "has appropriate description" do
        expect(lookback_info[:description]).to include("Lookback")
        expect(lookback_info[:description]).to include("prior")
      end

      it "has valid examples that can be parsed" do
        lookback_info[:examples].each do |example|
          notation = example.split(" - ").first
          expect { SOF::Cycle.for(notation) }.not_to raise_error
        end
      end
    end

    describe "C (Calendar)" do
      let(:calendar_info) { kind["C"] }

      it "has appropriate description" do
        expect(calendar_info[:description]).to include("Calendar")
      end

      it "has valid examples that can be parsed" do
        calendar_info[:examples].each do |example|
          notation = example.split(" - ").first
          expect { SOF::Cycle.for(notation) }.not_to raise_error
        end
      end
    end
  end

  describe "period section" do
    let(:period) { legend["period"] }

    it "includes all period notations" do
      period_keys = %w[D W M Q Y]
      expect(period.keys).to include(*period_keys)
    end

    %w[D W M Q Y].each do |period_code|
      context "#{period_code} period" do
        let(:period_info) { period[period_code] }

        it "has description" do
          expect(period_info[:description]).to be_a(String)
          expect(period_info[:description]).not_to be_empty
        end

        it "has examples showing usage in context" do
          expect(period_info[:examples]).to be_an(Array)
          expect(period_info[:examples].size).to be >= 2
        end
      end
    end
  end

  describe "date section" do
    let(:date) { legend["date"] }

    it "includes from notation" do
      expect(date).to have_key("F")
    end

    it "has appropriate description for from" do
      expect(date["F"][:description]).to include("From")
      expect(date["F"][:description]).to include("anchor date")
    end
  end

  describe "parseable examples" do
    it "all examples containing full notations can be parsed" do
      legend.each do |category, components|
        components.each do |key, info|
          next unless info.is_a?(Hash) && info[:examples]

          info[:examples].each do |example|
            # Extract notation part (before " - " if present)
            notation = example.split(" - ").first

            # Skip if it's just a component description (like "D" by itself)
            next if notation.length <= 2 && notation =~ /^[DWMQY]/

            # Skip if it doesn't start with V (not a complete notation)
            next unless notation.start_with?("V")

            expect { SOF::Cycle.for(notation) }.not_to raise_error,
              "Failed to parse example '#{notation}' from #{category}/#{key}"
          end
        end
      end
    end
  end
end
