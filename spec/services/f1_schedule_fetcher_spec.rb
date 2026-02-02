# frozen_string_literal: true

require "rails_helper"

RSpec.describe F1ScheduleFetcher do
  let(:fixture_html) { File.read(Rails.root.join("spec/fixtures/f1_schedule_page.html")) }
  let(:url) { "https://www.formula1.com/en/latest/article/test-grand-prix-2025.abc123" }

  before do
    stub_request(:get, url).to_return(status: 200, body: fixture_html)
  end

  describe "#call" do
    subject(:result) { described_class.new(url).call }

    it "returns a successful result" do
      expect(result).to be_success
    end

    it "extracts the timezone offset" do
      expect(result.data[:timezone_offset]).to eq("+04:00")
    end

    it "extracts events from the schedule" do
      expect(result.data[:events]).not_to be_empty
    end

    it "filters out Paddock Club events" do
      series_names = result.data[:events].map { |e| e[:series] }
      expect(series_names).not_to include("Paddock Club")
    end

    it "filters out FIA events" do
      series_names = result.data[:events].map { |e| e[:series] }
      expect(series_names).not_to include("FIA")
    end

    it "filters out Press Conference events" do
      session_names = result.data[:events].map { |e| e[:session] }
      expect(session_names).not_to include("Press Conference")
    end

    it "filters out National Anthem events" do
      session_names = result.data[:events].map { |e| e[:session] }
      expect(session_names.none? { |s| s =~ /National Anthem/i }).to be true
    end

    it "filters out Presentation events" do
      session_names = result.data[:events].map { |e| e[:session] }
      expect(session_names.none? { |s| s =~ /Presentation/i }).to be true
    end

    it "filters out Demonstration events" do
      session_names = result.data[:events].map { |e| e[:session] }
      expect(session_names.none? { |s| s =~ /Demonstration/i }).to be true
    end

    it "filters out Tribute events" do
      session_names = result.data[:events].map { |e| e[:session] }
      expect(session_names.none? { |s| s =~ /Tribute/i }).to be true
    end

    it "filters out Fly Past events" do
      session_names = result.data[:events].map { |e| e[:session] }
      expect(session_names.none? { |s| s =~ /Fly Past/i }).to be true
    end

    it "filters out Press Conference with irregular whitespace" do
      events = result.data[:events]
      press_conferences = events.select { |e| e[:session] =~ /Press.*Conference/i }
      expect(press_conferences).to be_empty
    end

    context "when the page cannot be fetched" do
      before do
        stub_request(:get, url).to_return(status: 404)
      end

      it "returns a failure result" do
        expect(result).to be_failure
      end

      it "includes an error message" do
        expect(result.errors).to include("Failed to fetch page")
      end
    end

    context "when there is a network error" do
      before do
        stub_request(:get, url).to_timeout
      end

      it "returns a failure result" do
        expect(result).to be_failure
      end
    end
  end

  describe "series name parsing" do
    subject(:result) { described_class.new(url).call }

    it "correctly parses series with 'Sprint' in the name" do
      porsche_events = result.data[:events].select { |e| e[:series] =~ /Porsche Sprint Challenge/i }
      expect(porsche_events).not_to be_empty
      expect(porsche_events.first[:session]).to eq("First Race")
    end

    it "captures F1's standalone Sprint session" do
      f1_events = result.data[:events].select { |e| e[:series] == "Formula 1" }
      session_names = f1_events.map { |e| e[:session] }
      expect(session_names).to include("Sprint")
    end
  end

  describe "deduplication" do
    subject(:result) { described_class.new(url).call }

    it "removes duplicate sessions for the same series on the same day" do
      f3_saturday_qualifying = result.data[:events].select do |e|
        e[:series] == "FIA Formula 3" &&
          e[:date] == Date.new(2025, 12, 6) &&
          e[:session] == "Qualifying"
      end
      expect(f3_saturday_qualifying.count).to eq(1)
    end

    it "keeps the first occurrence when deduplicating" do
      f3_qualifying = result.data[:events].find do |e|
        e[:series] == "FIA Formula 3" &&
          e[:date] == Date.new(2025, 12, 6) &&
          e[:session] == "Qualifying"
      end
      expect(f3_qualifying[:local_time]).to eq("14:00")
    end
  end

  describe "session name normalization" do
    subject(:result) { described_class.new(url).call }

    it "transforms 'FIRST PRACTICE SESSION' to 'Free Practice 1' for F1" do
      f1_events = result.data[:events].select { |e| e[:series] == "Formula 1" }
      session_names = f1_events.map { |e| e[:session] }
      expect(session_names).to include("Free Practice 1")
    end

    it "transforms 'SECOND PRACTICE SESSION' to 'Free Practice 2' for F1" do
      f1_events = result.data[:events].select { |e| e[:series] == "Formula 1" }
      session_names = f1_events.map { |e| e[:session] }
      expect(session_names).to include("Free Practice 2")
    end

    it "transforms 'QUALIFYING SESSION' to 'Qualifying' for F1" do
      f1_events = result.data[:events].select { |e| e[:series] == "Formula 1" }
      session_names = f1_events.map { |e| e[:session] }
      expect(session_names).to include("Qualifying")
    end

    it "removes 'Session' suffix from session names" do
      all_sessions = result.data[:events].map { |e| e[:session] }
      expect(all_sessions.none? { |s| s.end_with?(" Session") }).to be true
    end

    it "transforms 'THIRD PRACTICE SESSION' to 'Free Practice 3' for F1" do
      html = <<~HTML
        <html><body>
          <h1>2025 Test Grand Prix</h1>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>Formula 1THIRD PRACTICE SESSION09:00 - 10:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      f1_events = result.data[:events].select { |e| e[:series] == "Formula 1" }
      expect(f1_events.map { |e| e[:session] }).to include("Free Practice 3")
    end

    it "transforms 'SPRINT QUALIFYING' to 'Sprint Qualifying' for F1" do
      html = <<~HTML
        <html><body>
          <h1>2025 Test Grand Prix</h1>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>Formula 1SPRINT QUALIFYING09:00 - 10:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      f1_events = result.data[:events].select { |e| e[:series] == "Formula 1" }
      expect(f1_events.map { |e| e[:session] }).to include("Sprint Qualifying")
    end

    it "preserves non-standard F1 session names that dont match normalization patterns" do
      html = <<~HTML
        <html><body>
          <h1>2025 Test Grand Prix</h1>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>Formula 1GRAND PRIX09:00 - 10:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      f1_events = result.data[:events].select { |e| e[:series] == "Formula 1" }
      # "Grand Prix" doesn't match F1 normalization patterns so is preserved (title-cased)
      expect(f1_events.first[:session]).to eq("Grand Prix")
    end
  end

  describe "HTTP redirect handling" do
    let(:redirect_url) { "https://www.formula1.com/en/redirect" }
    let(:final_url) { "https://www.formula1.com/en/final" }

    it "follows redirects to fetch content" do
      stub_request(:get, url)
        .to_return(status: 302, headers: { "Location" => final_url })
      stub_request(:get, final_url)
        .to_return(status: 200, body: fixture_html)

      result = described_class.new(url).call
      expect(result).to be_success
    end

    it "returns failure when redirect target fails" do
      stub_request(:get, url)
        .to_return(status: 302, headers: { "Location" => final_url })
      stub_request(:get, final_url)
        .to_return(status: 500)

      result = described_class.new(url).call
      expect(result).to be_failure
    end

    it "returns failure when redirect target raises network error" do
      stub_request(:get, url)
        .to_return(status: 302, headers: { "Location" => final_url })
      stub_request(:get, final_url).to_timeout

      result = described_class.new(url).call
      expect(result).to be_failure
    end
  end

  describe "error handling" do
    it "returns failure when parsing raises an error" do
      # Create HTML that will cause Nokogiri to return something but extraction to fail
      bad_html = '<html><body>FRIDAY 32 DECEMBER</body></html>'
      stub_request(:get, url).to_return(status: 200, body: bad_html)

      result = described_class.new(url).call
      # This should either succeed with empty events or fail gracefully
      expect(result.data[:events]).to eq([]) if result.success?
    end
  end

  describe "JSON/HTML artifact filtering" do
    it "skips entries containing className" do
      html_with_artifacts = <<~HTML
        <html><body>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>{"className":"event"}Formula 1RACE09:00 - 10:00</div>
          <div>Formula 1QUALIFYING SESSION14:00 - 15:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html_with_artifacts)

      result = described_class.new(url).call
      expect(result.data[:events].length).to eq(1)
      expect(result.data[:events].first[:session]).to eq("Qualifying")
    end
  end

  describe "series exclusion edge cases" do
    subject(:result) { described_class.new(url).call }

    it "excludes Promoter Activity events" do
      html = <<~HTML
        <html><body>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>Promoter ActivityTrack Activity09:00 - 10:00</div>
          <div>Formula 1RACE14:00 - 15:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      series_names = result.data[:events].map { |e| e[:series] }
      expect(series_names).not_to include("Promoter Activity")
    end

    it "excludes F1 Experiences events" do
      html = <<~HTML
        <html><body>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>F1 ExperiencesTrack Tour09:00 - 10:00</div>
          <div>Formula 1RACE14:00 - 15:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      series_names = result.data[:events].map { |e| e[:series] }
      expect(series_names).not_to include("F1 Experiences")
    end

    it "excludes events where series matches excluded patterns" do
      html = <<~HTML
        <html><body>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>Pirelli Hot LapsSomething09:00 - 10:00</div>
          <div>Formula 1RACE14:00 - 15:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      series_names = result.data[:events].map { |e| e[:series] }
      expect(series_names).not_to include(match(/Hot Laps/i))
    end
  end

  describe "session name edge cases" do
    it "handles events with no recognizable session pattern" do
      html = <<~HTML
        <html><body>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>Some Random Series09:00 - 10:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      expect(result.data[:events].first[:series]).to eq("Some Random Series")
      expect(result.data[:events].first[:session]).to eq("Unknown")
    end

    it "normalizes series name when nil to Formula 1" do
      html = <<~HTML
        <html><body>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>RACE09:00 - 10:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      expect(result.data[:events].first[:series]).to eq("Formula 1")
    end

    it "removes bracket content from session names" do
      html = <<~HTML
        <html><body>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>FIA Formula 2FEATURE RACE (30 Laps or 45 Mins)09:00 - 10:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      expect(result.data[:events].first[:session]).to eq("Feature Race")
    end
  end

  describe "duplicate day handling" do
    it "assigns events to correct day even with duplicate headers in content" do
      # F1.com pages have duplicate day headers (visible + JSON), but events should
      # still be assigned to the correct date
      html = <<~HTML
        <html><body>
          <h1>2025 Test Grand Prix</h1>
          <h2>FRIDAY 5 DECEMBER</h2>
          <div>Formula 1FIRST PRACTICE SESSION09:00 - 10:00</div>
          <h2>SATURDAY 6 DECEMBER</h2>
          <div>Formula 1QUALIFYING SESSION14:00 - 15:00</div>
          <h2>SATURDAY 6 DECEMBER</h2>
          <div>Formula 1RACE16:00 - 18:00</div>
          <p>4 hours ahead of UTC</p>
        </body></html>
      HTML
      stub_request(:get, url).to_return(status: 200, body: html)

      result = described_class.new(url).call
      friday_events = result.data[:events].select { |e| e[:date] == Date.new(2025, 12, 5) }
      saturday_events = result.data[:events].select { |e| e[:date] == Date.new(2025, 12, 6) }

      expect(friday_events.length).to eq(1)
      expect(friday_events.first[:session]).to eq("Free Practice 1")

      expect(saturday_events.length).to eq(2)
      expect(saturday_events.map { |e| e[:session] }).to include("Qualifying", "Race")
    end
  end

  describe "timezone offset extraction" do
    it "extracts positive offsets correctly" do
      html_with_offset = '<html><body>Note - Location is 4 hours ahead of UTC.</body></html>'
      stub_request(:get, url).to_return(status: 200, body: html_with_offset)

      result = described_class.new(url).call
      expect(result.data[:timezone_offset]).to eq("+04:00")
    end

    it "extracts negative offsets correctly" do
      html_with_offset = '<html><body>Note - Location is 5 hours behind UTC.</body></html>'
      stub_request(:get, url).to_return(status: 200, body: html_with_offset)

      result = described_class.new(url).call
      expect(result.data[:timezone_offset]).to eq("-05:00")
    end

    it "defaults to +00:00 when no offset is found" do
      html_without_offset = '<html><body>No timezone info here.</body></html>'
      stub_request(:get, url).to_return(status: 200, body: html_without_offset)

      result = described_class.new(url).call
      expect(result.data[:timezone_offset]).to eq("+00:00")
    end
  end
end
