require "rails_helper"

RSpec.describe WeekendsHelper, type: :helper do
  describe "#event_row_classes" do
    let(:weekend) { build(:weekend) }
    let(:day) { build(:day, weekend: weekend, date: Date.tomorrow) }
    let(:series) { build(:series, name: "Formula 1") }
    let(:session) { build(:session, series: series) }
    let(:event) { build(:event, day: day, session: session, start_time: Time.parse("14:00")) }

    context "when event is Formula 1" do
      it "includes f1 class" do
        result = helper.event_row_classes(event, nil)
        expect(result).to include("f1")
      end
    end

    context "when event is not Formula 1" do
      let(:series) { build(:series, name: "Formula 2") }

      it "does not include f1 class" do
        result = helper.event_row_classes(event, nil)
        expect(result).not_to include("f1")
      end
    end

    context "when event is past" do
      let(:day) { build(:day, weekend: weekend, date: Date.yesterday) }

      it "includes past-event class" do
        result = helper.event_row_classes(event, nil)
        expect(result).to include("past-event")
      end
    end

    context "when event is not past" do
      it "does not include past-event class" do
        result = helper.event_row_classes(event, nil)
        expect(result).not_to include("past-event")
      end
    end

    context "when event is the next event" do
      it "includes next-event class" do
        result = helper.event_row_classes(event, event)
        expect(result).to include("next-event")
      end
    end

    context "when event is not the next event" do
      let(:other_event) { build(:event, id: 999) }

      it "does not include next-event class" do
        result = helper.event_row_classes(event, other_event)
        expect(result).not_to include("next-event")
      end
    end

    context "when next_event is nil" do
      it "does not include next-event class" do
        result = helper.event_row_classes(event, nil)
        expect(result).not_to include("next-event")
      end
    end

    context "when event has multiple applicable classes" do
      let(:day) { build(:day, weekend: weekend, date: Date.yesterday) }

      it "includes all applicable classes" do
        result = helper.event_row_classes(event, nil)
        expect(result).to include("f1")
        expect(result).to include("past-event")
      end
    end

    context "when event has no applicable classes" do
      let(:series) { build(:series, name: "Formula 2") }
      let(:day) { build(:day, weekend: weekend, date: Date.tomorrow) }

      it "returns empty string" do
        result = helper.event_row_classes(event, nil)
        expect(result).to eq("")
      end
    end
  end

  describe "#formatted_utc_offset" do
    it "converts a positive ISO-style offset to UTC+H" do
      expect(helper.formatted_utc_offset("+02:00")).to eq("UTC+2")
    end

    it "converts a negative ISO-style offset to UTC-H" do
      expect(helper.formatted_utc_offset("-04:00")).to eq("UTC-4")
    end

    it "converts a double-digit hour offset" do
      expect(helper.formatted_utc_offset("+11:00")).to eq("UTC+11")
    end

    it "keeps minutes when they are non-zero" do
      expect(helper.formatted_utc_offset("+05:30")).to eq("UTC+5:30")
    end

    it "returns an already-normalized offset unchanged" do
      expect(helper.formatted_utc_offset("UTC+3")).to eq("UTC+3")
    end

    it "returns blank input unchanged" do
      expect(helper.formatted_utc_offset(nil)).to be_nil
      expect(helper.formatted_utc_offset("")).to eq("")
    end
  end

  describe "#telegram_message" do
    let(:weekend) { build(:weekend, :monaco) }
    let(:weekend_url) { "https://f1.slashwolf.com/seasons/1/weekends/17" }

    subject(:message) { helper.telegram_message(weekend, "They actually got the circuit ready? Neat.", weekend_url) }

    it "includes the preamble verbatim" do
      expect(message).to start_with("They actually got the circuit ready? Neat.")
    end

    it "includes the local timezone and formatted UTC offset" do
      expect(message).to include("Europe/Monaco (UTC+2)")
    end

    it "includes the weekend URL" do
      expect(message).to include(weekend_url)
    end

    it "separates the preamble from the deterministic footer with a blank line" do
      expect(message).to include("Neat.\n\nAll times are in")
    end
  end
end
