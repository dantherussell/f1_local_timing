require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:day) }
    it { is_expected.to belong_to(:session) }
  end

  describe 'delegations' do
    it 'delegates weekend to day' do
      weekend = create(:weekend)
      day = weekend.days.first
      event = build(:event, day: day)
      expect(event.weekend).to eq(weekend)
    end

    it 'delegates formatted_date to day' do
      day = build(:day, date: Date.new(2024, 5, 26))
      event = build(:event, day: day)
      expect(event.formatted_date).to eq('Sunday 26 May')
    end
  end

  describe 'factory' do
    it 'creates a valid event' do
      event = build(:event)
      expect(event).to be_valid
    end
  end

  describe '#time_offset' do
    context 'when event has its own local_time_offset' do
      it 'returns the event offset' do
        event = build(:event, local_time_offset: '+03:00')
        expect(event.time_offset).to eq('+03:00')
      end
    end

    context 'when event has no local_time_offset' do
      it 'returns the day offset' do
        day = build(:day, local_time_offset: '+02:00')
        event = build(:event, day: day, local_time_offset: nil)
        expect(event.time_offset).to eq('+02:00')
      end
    end

    context 'when event and day have no local_time_offset' do
      it 'returns the weekend offset' do
        weekend = build(:weekend, local_time_offset: '+09:00')
        day = build(:day, weekend: weekend, local_time_offset: nil)
        event = build(:event, day: day, local_time_offset: nil)
        expect(event.time_offset).to eq('+09:00')
      end
    end

    context 'when event has blank local_time_offset' do
      it 'returns the day offset' do
        weekend = build(:weekend, local_time_offset: '+09:00')
        day = build(:day, weekend: weekend, local_time_offset: nil)
        event = build(:event, day: day, local_time_offset: '')
        expect(event.time_offset).to eq('+09:00')
      end
    end
  end

  describe '#circuit_time' do
    it 'converts UTC time to track-local time' do
      weekend = build(:weekend, local_time_offset: '+02:00')
      day = build(:day, weekend: weekend, date: Date.new(2024, 5, 26))
      event = build(:event, day: day, start_time: Time.parse('14:00'))
      # 14:00 UTC + 2 hours = 16:00 track time
      expect(event.circuit_time).to eq('16:00')
    end

    it 'handles negative offsets correctly' do
      weekend = build(:weekend, local_time_offset: '-08:00')
      day = build(:day, weekend: weekend, date: Date.new(2024, 11, 20))
      event = build(:event, day: day, start_time: Time.parse('00:30'))
      # 00:30 UTC - 8 hours = 16:30 track time (previous day)
      expect(event.circuit_time).to eq('16:30')
    end

    it 'returns nil when start_time is missing' do
      event = build(:event, start_time: nil)
      expect(event.circuit_time).to be_nil
    end
  end

  describe '#track_datetime' do
    it 'converts UTC datetime to track timezone' do
      weekend = build(:weekend, local_time_offset: '+02:00')
      day = build(:day, weekend: weekend, date: Date.new(2024, 5, 26))
      event = build(:event, day: day, start_time: Time.parse('14:00'))

      expect(event.track_datetime.hour).to eq(16)
      expect(event.track_datetime.offset).to eq(Rational(2, 24))
    end

    it 'returns nil when start_datetime is nil' do
      event = build(:event, start_time: nil)
      expect(event.track_datetime).to be_nil
    end
  end

  describe '#track_date' do
    it 'returns the date in track timezone' do
      weekend = build(:weekend, local_time_offset: '-08:00')
      day = build(:day, weekend: weekend, date: Date.new(2024, 11, 20))
      event = build(:event, day: day, start_time: Time.parse('00:30'))
      # 00:30 UTC on Nov 20 = 16:30 on Nov 19 at track (UTC-8)
      expect(event.track_date).to eq(Date.new(2024, 11, 19))
    end

    it 'returns nil when track_datetime is nil' do
      event = build(:event, start_time: nil)
      expect(event.track_date).to be_nil
    end
  end

  describe '#formatted_track_date' do
    it 'returns the formatted date in track timezone' do
      weekend = build(:weekend, local_time_offset: '-08:00')
      day = build(:day, weekend: weekend, date: Date.new(2024, 11, 20))
      event = build(:event, day: day, start_time: Time.parse('00:30'))
      expect(event.formatted_track_date).to eq('Tuesday 19 November')
    end

    it 'returns nil when track_date is nil' do
      event = build(:event, start_time: nil)
      expect(event.formatted_track_date).to be_nil
    end
  end

  describe '#date' do
    it 'returns the formatted date from day' do
      day = build(:day, date: Date.new(2024, 5, 26))
      event = build(:event, day: day)
      expect(event.date).to eq('Sunday 26 May')
    end
  end

  describe '#start_time_time_field' do
    it 'returns start_time when present' do
      event = build(:event, start_time: Time.parse('14:30'))
      expect(event.start_time_time_field.strftime('%H:%M')).to eq('14:30')
    end

    it 'returns nil when start_time is nil' do
      event = build(:event, start_time: nil)
      expect(event.start_time_time_field).to be_nil
    end
  end

  describe '#series_name' do
    context 'when session has a series' do
      it 'returns the series name' do
        series = build(:series, name: 'Formula 1')
        session = build(:session, series: series)
        event = build(:event, session: session)
        expect(event.series_name).to eq('Formula 1')
      end
    end

    context 'when session is nil' do
      it 'returns the racing_class' do
        event = build(:event, session: nil, racing_class: 'Porsche Supercup')
        event.instance_variable_set(:@session, nil)
        allow(event).to receive(:session).and_return(nil)
        expect(event.series_name).to eq('Porsche Supercup')
      end
    end
  end

  describe '#session_name' do
    context 'when event has a session' do
      it 'returns the session name' do
        session = build(:session, name: 'Qualifying')
        event = build(:event, session: session, name: 'Old Name')
        expect(event.session_name).to eq('Qualifying')
      end
    end

    context 'when session is nil' do
      it 'returns the event name' do
        event = build(:event, session: nil, name: 'Sprint Race')
        event.instance_variable_set(:@session, nil)
        allow(event).to receive(:session).and_return(nil)
        expect(event.session_name).to eq('Sprint Race')
      end
    end
  end

  describe 'virtual attributes for form fields' do
    describe '#start_time_time_field=' do
      it 'stores the time string' do
        event = Event.new
        event.start_time_time_field = '14:30'
        expect(event.instance_variable_get(:@start_time_time_field)).to eq('14:30:00')
      end
    end
  end

  describe 'before_save callback' do
    it 'converts time field to time on save' do
      event = build(:event)
      event.start_time_time_field = '15:00'
      event.save!

      expect(event.start_time.hour).to eq(15)
      expect(event.start_time.min).to eq(0)
    end
  end
end
