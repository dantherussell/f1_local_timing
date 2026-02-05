# frozen_string_literal: true

require "rails_helper"

RSpec.describe F1Schedule::EventNormalizer do
  subject(:normalizer) { described_class.new }

  describe "#normalize_series" do
    it "returns 'Formula 1' for nil" do
      expect(normalizer.normalize_series(nil)).to eq("Formula 1")
    end

    it "returns 'Formula 1' for 'Unknown'" do
      expect(normalizer.normalize_series("Unknown")).to eq("Formula 1")
    end

    it "converts FORMULA to Formula" do
      expect(normalizer.normalize_series("FORMULA 1")).to eq("Formula 1")
    end

    it "preserves FIA Formula series" do
      expect(normalizer.normalize_series("FIA FORMULA 2")).to eq("FIA Formula 2")
    end

    it "strips whitespace" do
      expect(normalizer.normalize_series("  Formula 1  ")).to eq("Formula 1")
    end

    it "preserves other series names" do
      expect(normalizer.normalize_series("F1 Academy")).to eq("F1 Academy")
    end
  end

  describe "#normalize_session" do
    context "with F1 series" do
      let(:series) { "Formula 1" }

      it "normalizes First Practice to Free Practice 1" do
        expect(normalizer.normalize_session("First Practice", series)).to eq("Free Practice 1")
      end

      it "normalizes FIRST PRACTICE to Free Practice 1" do
        expect(normalizer.normalize_session("FIRST PRACTICE", series)).to eq("Free Practice 1")
      end

      it "normalizes Second Practice to Free Practice 2" do
        expect(normalizer.normalize_session("Second Practice", series)).to eq("Free Practice 2")
      end

      it "normalizes Third Practice to Free Practice 3" do
        expect(normalizer.normalize_session("Third Practice", series)).to eq("Free Practice 3")
      end

      it "normalizes Sprint Qualifying" do
        expect(normalizer.normalize_session("SPRINT QUALIFYING", series)).to eq("Sprint Qualifying")
      end

      it "normalizes Sprint Race to Sprint" do
        expect(normalizer.normalize_session("Sprint Race", series)).to eq("Sprint")
      end

      it "normalizes standalone Sprint" do
        expect(normalizer.normalize_session("SPRINT", series)).to eq("Sprint")
      end

      it "normalizes Qualifying" do
        expect(normalizer.normalize_session("QUALIFYING", series)).to eq("Qualifying")
      end

      it "normalizes Race" do
        expect(normalizer.normalize_session("RACE", series)).to eq("Race")
      end

      it "preserves non-standard session names (titlecased)" do
        expect(normalizer.normalize_session("GRAND PRIX", series)).to eq("Grand Prix")
      end
    end

    context "with nil series (defaults to F1)" do
      it "applies F1 normalizations" do
        expect(normalizer.normalize_session("First Practice", nil)).to eq("Free Practice 1")
      end
    end

    context "with non-F1 series" do
      let(:series) { "FIA Formula 2" }

      it "does not apply F1-specific normalizations" do
        expect(normalizer.normalize_session("First Practice", series)).to eq("First Practice")
      end

      it "still removes Session suffix" do
        expect(normalizer.normalize_session("Qualifying Session", series)).to eq("Qualifying")
      end

      it "still removes brackets" do
        expect(normalizer.normalize_session("Feature Race (30 Laps)", series)).to eq("Feature Race")
      end

      it "still titlecases ALL CAPS" do
        expect(normalizer.normalize_session("SPRINT RACE", series)).to eq("Sprint Race")
      end
    end

    context "with bracket removal" do
      it "removes parenthetical content" do
        expect(normalizer.normalize_session("Feature Race (30 Laps or 45 Mins)", "FIA Formula 2")).to eq("Feature Race")
      end

      it "removes multiple brackets" do
        expect(normalizer.normalize_session("Race (A) (B)", "FIA Formula 2")).to eq("Race")
      end
    end

    context "with Session suffix removal" do
      it "removes trailing Session" do
        expect(normalizer.normalize_session("Qualifying Session", "FIA Formula 3")).to eq("Qualifying")
      end

      it "removes Session from middle of name" do
        expect(normalizer.normalize_session("Practice Session 1", "FIA Formula 3")).to eq("Practice 1")
      end
    end

    context "with nil or empty input" do
      it "returns Unknown for nil" do
        expect(normalizer.normalize_session(nil, "Formula 1")).to eq("Unknown")
      end

      it "returns Unknown for empty string" do
        expect(normalizer.normalize_session("", "Formula 1")).to eq("Unknown")
      end
    end

    context "with Part suffix removal" do
      it "removes - Part 1 suffix" do
        expect(normalizer.normalize_session("Qualifying - Part 1", "Supercars Championship")).to eq("Qualifying")
      end

      it "removes - Part 2 suffix" do
        expect(normalizer.normalize_session("Qualifying - Part 2", "Supercars Championship")).to eq("Qualifying")
      end

      it "removes - Part 3 suffix" do
        expect(normalizer.normalize_session("Qualifying - Part 3", "Supercars Championship")).to eq("Qualifying")
      end

      it "removes - Part 4 suffix" do
        expect(normalizer.normalize_session("Qualifying - Part 4", "Supercars Championship")).to eq("Qualifying")
      end

      it "handles varying whitespace around dash" do
        expect(normalizer.normalize_session("Qualifying-Part 1", "Supercars Championship")).to eq("Qualifying")
      end

      it "handles case-insensitive Part" do
        expect(normalizer.normalize_session("Qualifying - PART 1", "Supercars Championship")).to eq("Qualifying")
      end

      it "preserves names without Part suffix" do
        expect(normalizer.normalize_session("First Race", "Supercars Championship")).to eq("First Race")
      end

      it "does not remove Part from middle of name" do
        expect(normalizer.normalize_session("Part Time Practice", "Supercars Championship")).to eq("Part Time Practice")
      end
    end
  end
end
