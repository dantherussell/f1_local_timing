require 'rails_helper'

RSpec.describe Day, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:weekend) }
    it { is_expected.to have_many(:events).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:date) }

    describe 'date uniqueness' do
      it 'validates uniqueness scoped to weekend' do
        weekend = create(:weekend, first_day: nil, last_day: nil)
        create(:day, weekend: weekend, date: Date.new(2024, 5, 26))
        duplicate = build(:day, weekend: weekend, date: Date.new(2024, 5, 26))
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:date]).to include('has already been taken')
      end
    end
  end

  describe 'factory' do
    it 'creates a valid day' do
      day = build(:day)
      expect(day).to be_valid
    end
  end

  describe '#time_offset' do
    context 'when day has its own local_time_offset' do
      it 'returns the day offset' do
        day = build(:day, local_time_offset: '+03:00')
        expect(day.time_offset).to eq('+03:00')
      end
    end

    context 'when day has no local_time_offset' do
      it 'returns the weekend offset' do
        weekend = build(:weekend, local_time_offset: '+02:00')
        day = build(:day, weekend: weekend, local_time_offset: nil)
        expect(day.time_offset).to eq('+02:00')
      end
    end

    context 'when day has blank local_time_offset' do
      it 'returns the weekend offset' do
        weekend = build(:weekend, local_time_offset: '+09:00')
        day = build(:day, weekend: weekend, local_time_offset: '')
        expect(day.time_offset).to eq('+09:00')
      end
    end
  end

  describe '#formatted_date' do
    it 'returns the date formatted with day of week' do
      day = build(:day, date: Date.new(2024, 5, 26))
      expect(day.formatted_date).to eq('Sunday 26 May')
    end
  end

  describe 'delegation' do
    it 'delegates season to weekend' do
      season = build(:season, name: '2024')
      weekend = build(:weekend, season: season)
      day = build(:day, weekend: weekend)
      expect(day.season).to eq(season)
    end
  end
end
