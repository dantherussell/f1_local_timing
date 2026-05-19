# frozen_string_literal: true

require "rails_helper"

RSpec.describe F1Schedule::EventParser do
  subject(:parser) { described_class.new }

  let(:simple_html) do
    <<~HTML
      <html><body>
        <h1>2025 Test Grand Prix</h1>
        <h2>FRIDAY 5 DECEMBER</h2>
        <div>Formula 1FIRST PRACTICE SESSION09:00 - 10:00</div>
        <div>Formula 1SECOND PRACTICE SESSION14:00 - 15:00</div>
        <h2>SATURDAY 6 DECEMBER</h2>
        <div>Formula 1QUALIFYING SESSION15:00 - 16:00</div>
        <h2>SUNDAY 7 DECEMBER</h2>
        <div>Formula 1RACE17:00 - 19:00</div>
      </body></html>
    HTML
  end

  describe "#extract_events" do
    it "extracts events from HTML" do
      events = parser.extract_events(simple_html)
      expect(events.length).to eq(4)
    end

    it "parses dates correctly" do
      events = parser.extract_events(simple_html)
      expect(events.first[:date]).to eq(Date.new(2025, 12, 5))
    end

    it "parses local times correctly" do
      events = parser.extract_events(simple_html)
      expect(events.first[:local_time]).to eq("09:00")
    end

    it "normalizes series names" do
      events = parser.extract_events(simple_html)
      expect(events.first[:series]).to eq("Formula 1")
    end

    it "normalizes session names" do
      events = parser.extract_events(simple_html)
      expect(events.first[:session]).to eq("Free Practice 1")
    end

    context "with multiple series" do
      let(:multi_series_html) do
        <<~HTML
          <html><body>
            <h1>2025 Test Grand Prix</h1>
            <h2>FRIDAY 5 DECEMBER</h2>
            <div>FIA Formula 3FIRST PRACTICE SESSION09:00 - 09:45</div>
            <div>FIA Formula 2PRACTICE SESSION10:00 - 10:45</div>
            <div>Formula 1FIRST PRACTICE SESSION11:30 - 12:30</div>
          </body></html>
        HTML
      end

      it "extracts events for all series" do
        events = parser.extract_events(multi_series_html)
        series = events.map { |e| e[:series] }.uniq
        expect(series).to contain_exactly("FIA Formula 3", "FIA Formula 2", "Formula 1")
      end
    end

    context "with excluded events" do
      let(:html_with_exclusions) do
        <<~HTML
          <html><body>
            <h1>2025 Test Grand Prix</h1>
            <h2>FRIDAY 5 DECEMBER</h2>
            <div>Formula 1FIRST PRACTICE SESSION09:00 - 10:00</div>
            <div>Paddock ClubPit Lane Walk10:30 - 11:00</div>
            <div>Formula 1Press Conference12:00 - 12:30</div>
            <div>Formula 1QUALIFYING SESSION14:00 - 15:00</div>
          </body></html>
        HTML
      end

      it "filters out excluded events" do
        events = parser.extract_events(html_with_exclusions)
        series = events.map { |e| e[:series] }
        sessions = events.map { |e| e[:session] }

        expect(series).not_to include("Paddock Club")
        expect(sessions).not_to include(match(/Press Conference/i))
      end

      it "keeps valid events" do
        events = parser.extract_events(html_with_exclusions)
        expect(events.length).to eq(2)
      end
    end

    context "with duplicate events" do
      let(:html_with_duplicates) do
        <<~HTML
          <html><body>
            <h1>2025 Test Grand Prix</h1>
            <h2>SATURDAY 6 DECEMBER</h2>
            <div>FIA Formula 3QUALIFYING SESSION14:00 - 14:30</div>
            <h2>SATURDAY 6 DECEMBER</h2>
            <div>FIA Formula 3QUALIFYING SESSION15:00 - 15:30</div>
          </body></html>
        HTML
      end

      it "deduplicates by date/series/session" do
        events = parser.extract_events(html_with_duplicates)
        f3_qualifying = events.select { |e| e[:series] == "FIA Formula 3" && e[:session] == "Qualifying" }
        expect(f3_qualifying.length).to eq(1)
      end

      it "keeps the first occurrence" do
        events = parser.extract_events(html_with_duplicates)
        f3_qualifying = events.find { |e| e[:series] == "FIA Formula 3" }
        expect(f3_qualifying[:local_time]).to eq("14:00")
      end
    end

    context "with sole ordinal-prefixed sessions" do
      let(:f2_sole_practice_html) do
        <<~HTML
          <html><body>
            <h1>2026 Test Grand Prix</h1>
            <h2>FRIDAY 1 MAY</h2>
            <div>FIA Formula 2FIRST PRACTICE SESSION09:30 - 10:15</div>
          </body></html>
        HTML
      end

      let(:f2_two_practices_html) do
        <<~HTML
          <html><body>
            <h1>2026 Test Grand Prix</h1>
            <h2>FRIDAY 1 MAY</h2>
            <div>FIA Formula 2FIRST PRACTICE SESSION09:30 - 10:15</div>
            <h2>SATURDAY 2 MAY</h2>
            <div>FIA Formula 2SECOND PRACTICE SESSION09:30 - 10:15</div>
          </body></html>
        HTML
      end

      it "strips the ordinal prefix when only one practice exists for the series" do
        events = parser.extract_events(f2_sole_practice_html)
        f2_session = events.find { |e| e[:series] == "FIA Formula 2" }[:session]
        expect(f2_session).to eq("Practice")
      end

      it "preserves both ordinals when First and Second practice both exist" do
        events = parser.extract_events(f2_two_practices_html)
        f2_sessions = events.select { |e| e[:series] == "FIA Formula 2" }.map { |e| e[:session] }
        expect(f2_sessions).to contain_exactly("First Practice", "Second Practice")
      end
    end

    context "with F1 Academy opening/reverse grid races" do
      let(:f1_academy_html) do
        <<~HTML
          <html><body>
            <h1>2026 Test Grand Prix</h1>
            <h2>SATURDAY 23 MAY</h2>
            <div><span>F1 Academy</span><span>Opening Race (17 Laps, Max 30 Mins +1 Lap)</span><span>09:45 - 10:20</span></div>
            <div><span>F1 Academy</span><span>Reverse Grid Race (17 Laps, Max 30 Mins +1 Lap)</span><span>18:05 - 18:35</span></div>
          </body></html>
        HTML
      end

      it "correctly splits series and session when elements have no whitespace between them" do
        events = parser.extract_events(f1_academy_html)
        series = events.map { |e| e[:series] }
        expect(series).to all(eq("F1 Academy"))
      end

      it "parses Opening Race as the session" do
        events = parser.extract_events(f1_academy_html)
        sessions = events.map { |e| e[:session] }
        expect(sessions).to include("Opening Race")
      end

      it "parses Reverse Grid Race as the session" do
        events = parser.extract_events(f1_academy_html)
        sessions = events.map { |e| e[:session] }
        expect(sessions).to include("Reverse Grid Race")
      end
    end

    context "with year detection" do
      let(:html_2026) do
        <<~HTML
          <html><body>
            <h1>2026 Test Grand Prix</h1>
            <h2>FRIDAY 5 DECEMBER</h2>
            <div>Formula 1RACE09:00 - 10:00</div>
          </body></html>
        HTML
      end

      it "extracts year from content" do
        events = parser.extract_events(html_2026)
        expect(events.first[:date].year).to eq(2026)
      end
    end
  end
end
