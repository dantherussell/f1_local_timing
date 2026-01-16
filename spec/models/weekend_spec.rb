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

  describe '#timespan' do
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
end
