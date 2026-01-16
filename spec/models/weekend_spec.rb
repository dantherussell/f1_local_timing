require 'rails_helper'

RSpec.describe Weekend, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:season) }
    it { is_expected.to have_many(:events).dependent(:destroy) }
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
end
