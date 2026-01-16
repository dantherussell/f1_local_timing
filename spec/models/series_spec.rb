require 'rails_helper'

RSpec.describe Series, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid series' do
      series = build(:series)
      expect(series).to be_valid
    end

    it 'creates a Formula 1 series with trait' do
      series = build(:series, :f1)
      expect(series.name).to eq('Formula 1')
    end
  end
end
