require 'rails_helper'

RSpec.describe Season, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:weekends).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid season' do
      season = build(:season)
      expect(season).to be_valid
    end
  end
end
