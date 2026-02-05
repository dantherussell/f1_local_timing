# frozen_string_literal: true

require "rails_helper"

RSpec.describe F1Schedule::EventFilter do
  subject(:filter) { described_class.new }

  describe "#excluded?" do
    context "with excluded series" do
      it "excludes Paddock Club" do
        expect(filter.excluded?("Paddock Club", "Track Tour")).to be true
      end

      it "excludes Promoter Activity" do
        expect(filter.excluded?("Promoter Activity", "Something")).to be true
      end

      it "excludes F1 Experiences" do
        expect(filter.excluded?("F1 Experiences", "Hot Laps")).to be true
      end

      it "excludes standalone FIA" do
        expect(filter.excluded?("FIA", "National Anthem")).to be true
      end

      it "does not exclude FIA Formula 2" do
        expect(filter.excluded?("FIA Formula 2", "Sprint Race")).to be false
      end

      it "does not exclude FIA Formula 3" do
        expect(filter.excluded?("FIA Formula 3", "Qualifying")).to be false
      end
    end

    context "with excluded patterns in session" do
      it "excludes Hot Laps" do
        expect(filter.excluded?("Formula 1", "Pirelli Hot Laps")).to be true
      end

      it "excludes Parade" do
        expect(filter.excluded?("Formula 1", "Drivers' Parade")).to be true
      end

      it "excludes Anthem" do
        expect(filter.excluded?("Formula 1", "National Anthem")).to be true
      end

      it "excludes Press Conference" do
        expect(filter.excluded?("Formula 1", "Press Conference")).to be true
      end

      it "excludes Pit Stop" do
        expect(filter.excluded?("Formula 1", "Pit Stop Challenge")).to be true
      end

      it "excludes Presentation" do
        expect(filter.excluded?("Formula 1", "Drivers' Presentation")).to be true
      end

      it "excludes Demonstration" do
        expect(filter.excluded?("Formula 1", "Historic Car Demonstration")).to be true
      end

      it "excludes Tribute" do
        expect(filter.excluded?("Formula 1", "Eddie Jordan Tribute")).to be true
      end

      it "excludes Fly Past" do
        expect(filter.excluded?("Formula 1", "Air Display - Fly Past")).to be true
      end
    end

    context "with excluded patterns in series" do
      it "excludes when series contains Hot Laps" do
        expect(filter.excluded?("Pirelli Hot Laps", "Session")).to be true
      end
    end

    context "with valid events" do
      it "does not exclude Formula 1 Practice" do
        expect(filter.excluded?("Formula 1", "Free Practice 1")).to be false
      end

      it "does not exclude Formula 1 Qualifying" do
        expect(filter.excluded?("Formula 1", "Qualifying")).to be false
      end

      it "does not exclude Formula 1 Race" do
        expect(filter.excluded?("Formula 1", "Race")).to be false
      end

      it "does not exclude F1 Academy" do
        expect(filter.excluded?("F1 Academy", "Practice")).to be false
      end

      it "does not exclude Porsche Sprint Challenge" do
        expect(filter.excluded?("Porsche Sprint Challenge Brazil", "First Race")).to be false
      end
    end

    context "with nil values" do
      it "handles nil series" do
        expect(filter.excluded?(nil, "Race")).to be false
      end

      it "handles nil session" do
        expect(filter.excluded?("Formula 1", nil)).to be false
      end

      it "handles both nil" do
        expect(filter.excluded?(nil, nil)).to be false
      end
    end
  end
end
