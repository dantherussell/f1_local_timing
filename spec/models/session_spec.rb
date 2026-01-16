require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:series) }
    it { is_expected.to have_many(:events).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid session' do
      session = build(:session)
      expect(session).to be_valid
    end

    it 'creates a qualifying session with trait' do
      session = build(:session, :qualifying)
      expect(session.name).to eq('Qualifying')
    end
  end
end
