# frozen_string_literal: true

require "spec_helper"

module SOF
  RSpec.describe Parser, type: :value do
    describe ".load(hash)" do
      it "returns a Parser instance" do
        hash = {
          volume: 1,
          kind: "L",
          period_count: "180",
          period_key: "D"
        }
        expect(described_class.load(hash)).to eq described_class.new("V1L180D")
      end
    end

    describe ".for(notation_or_parser)" do
      context "when given a string" do
        it "returns a Parser instance" do
          expect(described_class.for("V1L180D")).to be_a(described_class)
        end
      end

      context "when given a Parser object" do
        it "returns the object" do
          parser = described_class.new("V1L180D")
          expect(described_class.for(parser)).to eq parser
        end
      end
    end

    describe "#initialize" do
      it "is case-insensitive" do
        aggregate_failures do
          expect(described_class.new("V1l180D").inspect).to eq "V1L180D"
          expect(described_class.new("V1L180d").to_s).to eq "V1L180D"
        end
      end
    end

    describe "#inspect & #to_s" do
      it "returns the string representation" do
        aggregate_failures do
          expect(described_class.new("V1L180D").inspect).to eq "V1L180D"
          expect(described_class.new("V1L180D").to_s).to eq "V1L180D"
        end
      end
    end

    describe "#valid?" do
      it "returns true if the notation is recognized" do
        aggregate_failures do
          expect(described_class.new("V1L180D")).to be_valid
          expect(described_class.new("XXX")).not_to be_valid
        end
      end
    end

    describe "#to_h" do
      it "returns a hash representation of the notation" do
        aggregate_failures do
          expect(described_class.new("V1L180D").to_h).to eq({
            volume: 1,
            kind: "L",
            period_count: "180",
            period_key: "D",
            from_date: nil
          })
          expect(described_class.new("V1W180D").to_h).to eq({
            volume: 1,
            kind: "W",
            period_count: "180",
            period_key: "D",
            from_date: nil
          })
          expect(described_class.new("V1W180DF2024-05-06").to_h).to eq({
            volume: 1,
            kind: "W",
            period_count: "180",
            period_key: "D",
            from_date: "2024-05-06"
          })
        end
      end
    end

    describe "#activated_notation(date)" do
      it "returns the activated notation" do
        date = "2024-05-06"
        aggregate_failures do
          expect(described_class.new("V1L180D").activated_notation(date)).to eq(
            "V1L180D"
          )
          expect(described_class.new("V1W180D").activated_notation(date)).to eq(
            "V1W180DF2024-05-06"
          )
          expect(described_class.new("V1W180DF2024-09-09").activated_notation(date)).to eq(
            "V1W180DF2024-05-06"
          )
        end
      end
    end

    describe "#dormant|_capable? & #active?" do
      it "returns true if the notation has a dormant variant" do
        aggregate_failures do
          expect(described_class.new("V1L180D")).not_to be_dormant_capable
          expect(described_class.new("V1L180D")).not_to be_dormant
          expect(described_class.new("V1L180D")).to be_active

          expect(described_class.new("V1W180D")).to be_dormant_capable
          expect(described_class.new("V1W180D")).to be_dormant
          expect(described_class.new("V1W180D")).not_to be_active

          expect(described_class.new("V1W180DF2024-09-09")).to be_dormant_capable
          expect(described_class.new("V1W180DF2024-09-09")).not_to be_dormant
          expect(described_class.new("V1W180DF2024-09-09")).to be_active
        end
      end
    end

    describe "#from|_date" do
      it "returns match[:from]|match[:from_date]" do
        aggregate_failures do
          expect(described_class.new("V1L180D").from).to be_nil
          expect(described_class.new("V1L180D").from_date).to be_nil
          expect(described_class.new("V1W10DF2024-04-09").from).to eq "F2024-04-09"
          expect(described_class.new("V1W10DF2024-04-09").from_date).to eq "2024-04-09"
        end
      end
    end

    describe "#period_count" do
      it "returns match[:period_count]" do
        aggregate_failures do
          expect(described_class.new("V1L180D").period_count).to eq "180"
          expect(described_class.new("V3C1Y").period_count).to eq "1"
          expect(described_class.new("V4").period_count).to be_nil
        end
      end
    end

    describe "#period_key" do
      it "returns match[:period_key]" do
        aggregate_failures do
          expect(described_class.new("V1L180D").period_key).to eq "D"
          expect(described_class.new("V3C1Y").period_key).to eq "Y"
          expect(described_class.new("V4").period_key).to be_nil
        end
      end
    end

    describe "#volume" do
      it "returns match[:volume]" do
        aggregate_failures do
          expect(described_class.new("L180D").volume).to eq 1
          expect(described_class.new("V1L180D").volume).to eq 1
          expect(described_class.new("V3C1Y").volume).to eq 3
          expect(described_class.new("V4").volume).to eq 4
        end
      end
    end

    describe "#kind" do
      it "returns match[:kind]" do
        aggregate_failures do
          expect(described_class.new("V1L180D").kind).to eq "L"
          expect(described_class.new("V1C1Y").kind).to eq "C"
          expect(described_class.new("V1").kind).to be_nil
        end
      end
    end

    describe "#parses?" do
      it "returns true if the object parses the notation_id" do
        aggregate_failures do
          expect(described_class.new("V1L180D").parses?("L")).to be true
          expect(described_class.new("V1C1Y").parses?("C")).to be true
          expect(described_class.new("V1").parses?(nil)).to be true
        end
      end
    end
  end
end
