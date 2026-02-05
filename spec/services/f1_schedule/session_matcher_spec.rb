# frozen_string_literal: true

require "rails_helper"

RSpec.describe F1Schedule::SessionMatcher do
  subject(:matcher) { described_class.new }

  describe "#split" do
    context "with practice sessions" do
      it "splits FIRST PRACTICE" do
        expect(matcher.split("Formula 1FIRST PRACTICE")).to eq([ "Formula 1", "FIRST PRACTICE" ])
      end

      it "splits SECOND PRACTICE" do
        expect(matcher.split("Formula 1SECOND PRACTICE SESSION")).to eq([ "Formula 1", "SECOND PRACTICE SESSION" ])
      end

      it "splits THIRD PRACTICE" do
        expect(matcher.split("Formula 1THIRD PRACTICE")).to eq([ "Formula 1", "THIRD PRACTICE" ])
      end

      it "splits generic PRACTICE" do
        expect(matcher.split("F1 AcademyPRACTICE SESSION")).to eq([ "F1 Academy", "PRACTICE SESSION" ])
      end
    end

    context "with sprint sessions" do
      it "splits SPRINT QUALIFYING" do
        expect(matcher.split("Formula 1SPRINT QUALIFYING")).to eq([ "Formula 1", "SPRINT QUALIFYING" ])
      end

      it "splits SPRINT RACE" do
        expect(matcher.split("FIA Formula 2SPRINT RACE")).to eq([ "FIA Formula 2", "SPRINT RACE" ])
      end

      it "splits standalone SPRINT" do
        expect(matcher.split("Formula 1SPRINT")).to eq([ "Formula 1", "SPRINT" ])
      end

      it "does not split Sprint Challenge series names" do
        result = matcher.split("Porsche Sprint Challenge BrazilFIRST RACE")
        expect(result[0]).to eq("Porsche Sprint Challenge Brazil")
        expect(result[1]).to eq("FIRST RACE")
      end
    end

    context "with qualifying sessions" do
      it "splits QUALIFYING SESSION" do
        expect(matcher.split("Formula 1QUALIFYING SESSION")).to eq([ "Formula 1", "QUALIFYING SESSION" ])
      end

      it "splits plain QUALIFYING" do
        expect(matcher.split("FIA Formula 3QUALIFYING")).to eq([ "FIA Formula 3", "QUALIFYING" ])
      end
    end

    context "with race sessions" do
      it "splits RACE" do
        expect(matcher.split("Formula 1RACE")).to eq([ "Formula 1", "RACE" ])
      end

      it "splits FEATURE RACE" do
        expect(matcher.split("FIA Formula 2FEATURE RACE")).to eq([ "FIA Formula 2", "FEATURE RACE" ])
      end

      it "splits FIRST RACE" do
        expect(matcher.split("Porsche CupFIRST RACE")).to eq([ "Porsche Cup", "FIRST RACE" ])
      end

      it "splits GRAND PRIX" do
        expect(matcher.split("Formula 1GRAND PRIX")).to eq([ "Formula 1", "GRAND PRIX" ])
      end
    end

    context "with whitespace handling" do
      it "normalizes multiple spaces" do
        expect(matcher.split("Formula 1  QUALIFYING")).to eq([ "Formula 1", "QUALIFYING" ])
      end

      it "removes 'Local time' text" do
        expect(matcher.split("Local timeFormula 1RACE")).to eq([ "Formula 1", "RACE" ])
      end

      it "handles leading/trailing whitespace" do
        expect(matcher.split("  Formula 1RACE  ")).to eq([ "Formula 1", "RACE" ])
      end
    end

    context "with no session pattern match" do
      it "returns series only with nil session" do
        expect(matcher.split("Some Unknown Series")).to eq([ "Some Unknown Series", nil ])
      end
    end

    context "with artifacts" do
      it "returns nil for className artifacts" do
        expect(matcher.split('{"className":"something"}RACE')).to eq([ nil, nil ])
      end

      it "returns nil for JSON artifacts" do
        expect(matcher.split('":"value"}RACE')).to eq([ nil, nil ])
      end
    end

    context "with nil or empty input" do
      it "returns nil for nil input" do
        expect(matcher.split(nil)).to eq([ nil, nil ])
      end

      it "returns nil for empty input after cleaning" do
        expect(matcher.split("Local time")).to eq([ nil, nil ])
      end
    end
  end
end
