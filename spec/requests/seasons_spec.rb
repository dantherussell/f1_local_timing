require 'rails_helper'

RSpec.describe 'Seasons', type: :request do
  around do |example|
    orig_username = ENV['ADMIN_USERNAME']
    orig_password = ENV['ADMIN_PASSWORD']
    ENV['ADMIN_USERNAME'] = 'admin'
    ENV['ADMIN_PASSWORD'] = 'password'
    example.run
  ensure
    ENV['ADMIN_USERNAME'] = orig_username
    ENV['ADMIN_PASSWORD'] = orig_password
  end

  describe 'GET /seasons' do
    it 'returns a successful response' do
      get seasons_path
      expect(response).to have_http_status(:success)
    end

    it 'displays all seasons' do
      create(:season, name: '2024 Season')
      create(:season, name: '2025 Season')

      get seasons_path
      expect(response.body).to include('2024 Season')
      expect(response.body).to include('2025 Season')
    end
  end

  describe 'GET /seasons/:id' do
    let(:season) { create(:season) }

    it 'returns a successful response' do
      get season_path(season)
      expect(response).to have_http_status(:success)
    end

    it 'orders weekends by race_number when all have race numbers' do
      create(:weekend, season: season, race_number: 3, gp_title: 'Third GP')
      create(:weekend, season: season, race_number: 1, gp_title: 'First GP')
      create(:weekend, season: season, race_number: 2, gp_title: 'Second GP')

      get season_path(season)
      expect(response.body).to match(/First GP.*Second GP.*Third GP/m)
    end

    it 'returns weekends without ordering when some lack race numbers' do
      create(:weekend, season: season, race_number: nil, gp_title: 'GP Without Number')
      create(:weekend, season: season, race_number: 1, gp_title: 'GP With Number')

      get season_path(season)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('GP Without Number')
      expect(response.body).to include('GP With Number')
    end
  end

  describe 'GET /seasons/new' do
    it 'requires authentication' do
      get new_season_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get new_season_path, headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /seasons' do
    it 'requires authentication' do
      post seasons_path, params: { season: { name: '2024 Season' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'creates a new season' do
        expect {
          post seasons_path, params: { season: { name: '2024 Season' } }, headers: auth_headers
        }.to change(Season, :count).by(1)
      end

      it 'redirects to the new season' do
        post seasons_path, params: { season: { name: '2024 Season' } }, headers: auth_headers
        expect(response).to redirect_to(season_path(Season.last))
      end

      it 'renders new with errors when create fails' do
        allow_any_instance_of(Season).to receive(:save).and_return(false)
        post seasons_path, params: { season: { name: '2024 Season' } }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /seasons/:id/edit' do
    let(:season) { create(:season) }

    it 'requires authentication' do
      get edit_season_path(season)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get edit_season_path(season), headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /seasons/:id' do
    let(:season) { create(:season, name: 'Old Name') }

    it 'requires authentication' do
      patch season_path(season), params: { season: { name: 'New Name' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'updates the season' do
        patch season_path(season), params: { season: { name: 'New Name' } }, headers: auth_headers
        expect(season.reload.name).to eq('New Name')
      end

      it 'redirects to the season' do
        patch season_path(season), params: { season: { name: 'New Name' } }, headers: auth_headers
        expect(response).to redirect_to(season_path(season))
      end

      it 'renders edit with errors when update fails' do
        allow_any_instance_of(Season).to receive(:update).and_return(false)
        patch season_path(season), params: { season: { name: 'New Name' } }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /seasons/:id' do
    let!(:season) { create(:season) }

    it 'requires authentication' do
      delete season_path(season)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'deletes the season' do
        expect {
          delete season_path(season), headers: auth_headers
        }.to change(Season, :count).by(-1)
      end

      it 'redirects to seasons index' do
        delete season_path(season), headers: auth_headers
        expect(response).to redirect_to(seasons_path)
      end
    end
  end

  describe 'GET /auth' do
    it 'requires authentication' do
      get auth_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'redirects to root when authenticated' do
      get auth_path, headers: auth_headers
      expect(response).to redirect_to(root_path)
    end
  end
end
