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
end
