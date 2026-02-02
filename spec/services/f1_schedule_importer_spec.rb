# frozen_string_literal: true

require "rails_helper"

RSpec.describe F1ScheduleImporter do
  let(:season) { create(:season) }
  let(:weekend) do
    create(:weekend,
           season: season,
           first_day: Date.new(2025, 12, 5),
           last_day: Date.new(2025, 12, 7),
           local_time_offset: "+00:00")
  end

  let(:schedule_data) do
    {
      timezone_offset: "+04:00",
      events: [
        { date: Date.new(2025, 12, 5), local_time: "13:30", series: "Formula 1", session: "Free Practice 1" },
        { date: Date.new(2025, 12, 5), local_time: "17:00", series: "Formula 1", session: "Free Practice 2" },
        { date: Date.new(2025, 12, 6), local_time: "14:00", series: "Formula 1", session: "Qualifying" },
        { date: Date.new(2025, 12, 7), local_time: "17:00", series: "Formula 1", session: "Race" }
      ]
    }
  end

  describe "#call" do
    subject(:result) { described_class.new(weekend, schedule_data).call }

    it "returns a successful result" do
      expect(result).to be_success
    end

    it "creates events for the weekend" do
      expect { result }.to change(Event, :count).by(4)
    end

    it "returns the count of events created" do
      expect(result.data[:events_created]).to eq(4)
    end

    it "creates events on the correct days" do
      result
      friday = weekend.days.find_by(date: Date.new(2025, 12, 5))
      expect(friday.events.count).to eq(2)
    end

    it "creates series records" do
      expect { result }.to change(Series, :count).by(1)
    end

    it "creates session records" do
      expect { result }.to change(Session, :count).by(4)
    end

    it "updates the weekend timezone offset" do
      result
      expect(weekend.reload.local_time_offset).to eq("+04:00")
    end

    context "when there are existing events" do
      let!(:existing_session) { create(:session) }
      let!(:existing_event) { create(:event, day: weekend.days.first, session: existing_session) }

      it "deletes existing events before importing" do
        result
        expect(Event.exists?(existing_event.id)).to be false
      end
    end

    context "when using existing series and sessions" do
      let!(:f1_series) { Series.create!(name: "Formula 1") }
      let!(:fp1_session) { f1_series.sessions.create!(name: "Free Practice 1") }

      it "reuses existing series" do
        expect { result }.not_to change(Series, :count)
      end

      it "reuses existing sessions" do
        expect { result }.to change(Session, :count).by(3)
      end
    end
  end

  describe "time conversion" do
    subject(:result) { described_class.new(weekend, schedule_data).call }

    it "converts local time to UTC by subtracting the offset" do
      result
      friday = weekend.days.find_by(date: Date.new(2025, 12, 5))
      fp1_event = friday.events.find_by(name: "Free Practice 1")

      # 13:30 local at +04:00 = 09:30 UTC
      expect(fp1_event.start_time.strftime("%H:%M")).to eq("09:30")
    end

    it "handles time conversion for late times correctly" do
      result
      sunday = weekend.days.find_by(date: Date.new(2025, 12, 7))
      race_event = sunday.events.find_by(name: "Race")

      # 17:00 local at +04:00 = 13:00 UTC
      expect(race_event.start_time.strftime("%H:%M")).to eq("13:00")
    end
  end

  describe "event attributes" do
    subject(:result) { described_class.new(weekend, schedule_data).call }

    it "sets the session association" do
      result
      event = Event.last
      expect(event.session).to be_present
      expect(event.session.name).to eq("Race")
    end

    it "sets legacy racing_class field" do
      result
      event = Event.last
      expect(event.racing_class).to eq("Formula 1")
    end

    it "sets legacy name field" do
      result
      event = Event.last
      expect(event.name).to eq("Race")
    end
  end

  describe "error handling" do
    context "when an event date doesn't match any day" do
      subject(:result) { described_class.new(weekend, mismatched_schedule_data).call }

      let(:mismatched_schedule_data) do
        {
          timezone_offset: "+04:00",
          events: [
            { date: Date.new(2025, 12, 10), local_time: "13:30", series: "Formula 1", session: "Free Practice 1" }
          ]
        }
      end

      it "skips events for dates not in the weekend" do
        expect { result }.not_to change(Event, :count)
      end

      it "returns success with zero events created" do
        expect(result).to be_success
        expect(result.data[:events_created]).to eq(0)
      end
    end

    context "when a record validation fails" do
      before do
        allow(Event).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Event.new))
      end

      it "returns a failure result with validation message" do
        result = described_class.new(weekend, schedule_data).call
        expect(result).to be_failure
        expect(result.errors).to include(match(/Failed to import/))
      end
    end

    context "when an unexpected error occurs" do
      before do
        allow_any_instance_of(described_class).to receive(:import_events).and_raise(StandardError.new("Something went wrong"))
      end

      it "returns a failure result with error message" do
        result = described_class.new(weekend, schedule_data).call
        expect(result).to be_failure
        expect(result.errors).to include("Import error: Something went wrong")
      end
    end
  end
end
