require 'rails_helper'

RSpec.describe Weekend, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:season) }
    it { is_expected.to have_many(:days).dependent(:destroy) }
    it { is_expected.to have_many(:events).through(:days) }
  end

  describe 'factory' do
    it 'creates a valid weekend' do
      weekend = build(:weekend)
      expect(weekend).to be_valid
    end

    it 'creates a Monaco weekend with trait' do
      weekend = build(:weekend, :monaco)
      expect(weekend.gp_title).to eq('Monaco Grand Prix')
      expect(weekend.location).to eq('Monte Carlo')
    end

    it 'creates a Suzuka weekend with correct timezone' do
      weekend = build(:weekend, :suzuka)
      expect(weekend.local_time_offset).to eq('+09:00')
    end
  end

  describe 'validations' do
    it 'is valid when first_day is before last_day' do
      weekend = build(:weekend, first_day: Date.new(2024, 5, 24), last_day: Date.new(2024, 5, 26))
      expect(weekend).to be_valid
    end

    it 'is valid when first_day equals last_day' do
      weekend = build(:weekend, first_day: Date.new(2024, 5, 24), last_day: Date.new(2024, 5, 24))
      expect(weekend).to be_valid
    end

    it 'is invalid when first_day is after last_day' do
      weekend = build(:weekend, first_day: Date.new(2024, 5, 26), last_day: Date.new(2024, 5, 24))
      expect(weekend).not_to be_valid
      expect(weekend.errors[:first_day]).to include('must be before or equal to last day')
    end

    it 'is valid when both dates are blank' do
      weekend = build(:weekend, first_day: nil, last_day: nil)
      expect(weekend).to be_valid
    end
  end

  describe '#timespan' do
    context 'when no events exist' do
      it 'returns formatted date range when same month' do
        weekend = build(:weekend, first_day: Date.new(2024, 5, 24), last_day: Date.new(2024, 5, 26))
        expect(weekend.timespan).to eq('24-26 May')
      end

      it 'returns formatted date range when different months' do
        weekend = build(:weekend, first_day: Date.new(2024, 3, 29), last_day: Date.new(2024, 4, 1))
        expect(weekend.timespan).to eq('29 March - 1 April')
      end

      it 'returns nil when dates are blank' do
        weekend = build(:weekend, first_day: nil, last_day: nil)
        expect(weekend.timespan).to be_nil
      end
    end

    context 'when events exist' do
      it 'uses track dates from first and last events' do
        weekend = create(:weekend, first_day: Date.new(2024, 11, 20), last_day: Date.new(2024, 11, 22), local_time_offset: '+02:00')
        day1 = weekend.days.find_by(date: Date.new(2024, 11, 20))
        day2 = weekend.days.find_by(date: Date.new(2024, 11, 22))
        session = create(:session)

        # First event: UTC 08:00 on Nov 20 = 10:00 track time on Nov 20
        create(:event, day: day1, session: session, start_time: Time.parse('08:00'))
        # Last event: UTC 14:00 on Nov 22 = 16:00 track time on Nov 22
        create(:event, day: day2, session: session, start_time: Time.parse('14:00'))

        expect(weekend.timespan).to eq('20-22 November')
      end

      it 'adjusts dates when timezone shifts events to different days' do
        # UTC-8 timezone (e.g., Las Vegas)
        weekend = create(:weekend, first_day: Date.new(2024, 11, 20), last_day: Date.new(2024, 11, 22), local_time_offset: '-08:00')
        day1 = weekend.days.find_by(date: Date.new(2024, 11, 20))
        day2 = weekend.days.find_by(date: Date.new(2024, 11, 22))
        session = create(:session)

        # First event: UTC 02:00 on Nov 20 = 18:00 track time on Nov 19 (previous day!)
        create(:event, day: day1, session: session, start_time: Time.parse('02:00'))
        # Last event: UTC 06:00 on Nov 22 = 22:00 track time on Nov 21 (previous day!)
        create(:event, day: day2, session: session, start_time: Time.parse('06:00'))

        expect(weekend.timespan).to eq('19-21 November')
      end
    end
  end

  describe '#sync_days' do
    it 'creates days when weekend is saved with date range' do
      weekend = create(:weekend, first_day: Date.new(2024, 5, 24), last_day: Date.new(2024, 5, 26))
      expect(weekend.days.count).to eq(3)
      expect(weekend.days.pluck(:date)).to contain_exactly(
        Date.new(2024, 5, 24),
        Date.new(2024, 5, 25),
        Date.new(2024, 5, 26)
      )
    end

    it 'removes days outside new range when updated' do
      weekend = create(:weekend, first_day: Date.new(2024, 5, 24), last_day: Date.new(2024, 5, 26))
      expect(weekend.days.count).to eq(3)

      weekend.update!(first_day: Date.new(2024, 5, 25), last_day: Date.new(2024, 5, 26))
      expect(weekend.days.count).to eq(2)
      expect(weekend.days.pluck(:date)).to contain_exactly(
        Date.new(2024, 5, 25),
        Date.new(2024, 5, 26)
      )
    end

    it 'adds days when range is extended' do
      weekend = create(:weekend, first_day: Date.new(2024, 5, 25), last_day: Date.new(2024, 5, 26))
      expect(weekend.days.count).to eq(2)

      weekend.update!(first_day: Date.new(2024, 5, 24), last_day: Date.new(2024, 5, 26))
      expect(weekend.days.count).to eq(3)
    end

    it 'does not create days when dates are blank' do
      weekend = create(:weekend, first_day: nil, last_day: nil)
      expect(weekend.days.count).to eq(0)
    end
  end

  describe '#past?' do
    context 'when weekend has no events' do
      it 'returns false' do
        weekend = create(:weekend, first_day: Date.yesterday, last_day: Date.yesterday)
        expect(weekend.past?).to be false
      end
    end

    context 'when last event has no start_datetime' do
      it 'returns false' do
        weekend = create(:weekend, first_day: Date.yesterday, last_day: Date.yesterday)
        day = weekend.days.first
        session = create(:session)
        create(:event, day: day, session: session, start_time: nil)
        expect(weekend.past?).to be false
      end
    end

    context 'when last event is in the past' do
      it 'returns true' do
        weekend = create(:weekend, first_day: Date.yesterday, last_day: Date.yesterday)
        day = weekend.days.first
        session = create(:session)
        create(:event, day: day, session: session, start_time: Time.parse('10:00'))
        expect(weekend.past?).to be true
      end
    end

    context 'when last event is in the future' do
      it 'returns false' do
        weekend = create(:weekend, first_day: Date.tomorrow, last_day: Date.tomorrow)
        day = weekend.days.first
        session = create(:session)
        create(:event, day: day, session: session, start_time: Time.parse('10:00'))
        expect(weekend.past?).to be false
      end
    end

    context 'with multiple events spanning days' do
      it 'uses the last event to determine if past' do
        weekend = create(:weekend, first_day: Date.yesterday, last_day: Date.tomorrow)
        day_past = weekend.days.find_by(date: Date.yesterday)
        day_future = weekend.days.find_by(date: Date.tomorrow)
        session = create(:session)

        create(:event, day: day_past, session: session, start_time: Time.parse('10:00'))
        create(:event, day: day_future, session: session, start_time: Time.parse('14:00'))

        expect(weekend.past?).to be false
      end
    end
  end

  describe '#next_event' do
    context 'when weekend has no events' do
      it 'returns nil' do
        weekend = create(:weekend, first_day: Date.tomorrow, last_day: Date.tomorrow)
        expect(weekend.next_event).to be_nil
      end
    end

    context 'when all events are in the past' do
      it 'returns nil' do
        weekend = create(:weekend, first_day: Date.yesterday, last_day: Date.yesterday)
        day = weekend.days.first
        session = create(:session)
        create(:event, day: day, session: session, start_time: Time.parse('10:00'))
        expect(weekend.next_event).to be_nil
      end
    end

    context 'when all events are in the future' do
      it 'returns the first event' do
        weekend = create(:weekend, first_day: Date.tomorrow, last_day: Date.tomorrow)
        day = weekend.days.first
        session = create(:session)
        event1 = create(:event, day: day, session: session, start_time: Time.parse('10:00'))
        create(:event, day: day, session: session, start_time: Time.parse('14:00'))

        expect(weekend.next_event).to eq(event1)
      end
    end

    context 'with mix of past and future events' do
      it 'returns the first future event' do
        weekend = create(:weekend, first_day: Date.yesterday, last_day: Date.tomorrow)
        day_past = weekend.days.find_by(date: Date.yesterday)
        day_future = weekend.days.find_by(date: Date.tomorrow)
        session = create(:session)

        create(:event, day: day_past, session: session, start_time: Time.parse('10:00'))
        future_event = create(:event, day: day_future, session: session, start_time: Time.parse('14:00'))

        expect(weekend.next_event).to eq(future_event)
      end
    end

    context 'when event has no start_datetime' do
      it 'skips events without start_datetime' do
        weekend = create(:weekend, first_day: Date.tomorrow, last_day: Date.tomorrow)
        day = weekend.days.first
        session = create(:session)
        create(:event, day: day, session: session, start_time: nil)
        event_with_time = create(:event, day: day, session: session, start_time: Time.parse('14:00'))

        expect(weekend.next_event).to eq(event_with_time)
      end
    end
  end
end
