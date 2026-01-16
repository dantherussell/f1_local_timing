require 'rails_helper'

RSpec.describe 'Weekends', type: :request do
  let(:season) { create(:season) }

  before do
    ENV['ADMIN_USERNAME'] = 'admin'
    ENV['ADMIN_PASSWORD'] = 'password'
  end

  describe 'GET /seasons/:season_id/weekends/:id' do
    let(:weekend) { create(:weekend, season: season) }

    it 'returns a successful response' do
      get season_weekend_path(season, weekend)
      expect(response).to have_http_status(:success)
    end

    it 'displays the weekend details' do
      get season_weekend_path(season, weekend)
      expect(response.body).to include(weekend.gp_title)
    end

    it 'groups events by date' do
      session = create(:session)
      create(:event, weekend: weekend, session: session, start_time: DateTime.new(2024, 5, 24, 10, 0, 0), name: 'FP1')
      create(:event, weekend: weekend, session: session, start_time: DateTime.new(2024, 5, 25, 14, 0, 0), name: 'Qualifying')

      get season_weekend_path(season, weekend)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /seasons/:season_id/weekends/:id/print' do
    let(:weekend) { create(:weekend, season: season) }

    it 'returns a successful response' do
      get print_season_weekend_path(season, weekend)
      expect(response).to have_http_status(:success)
    end

    it 'uses the print layout' do
      get print_season_weekend_path(season, weekend)
      expect(response.body).not_to include('nav')
    end
  end

  describe 'GET /seasons/:season_id/weekends/new' do
    it 'requires authentication' do
      get new_season_weekend_path(season)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get new_season_weekend_path(season), headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /seasons/:season_id/weekends' do
    let(:valid_params) do
      {
        weekend: {
          gp_title: 'Monaco Grand Prix',
          location: 'Monte Carlo',
          timespan: 'May 23-26',
          local_timezone: 'Europe/Monaco',
          local_time_offset: '+02:00',
          race_number: 8
        }
      }
    end

    it 'requires authentication' do
      post season_weekends_path(season), params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'creates a new weekend' do
        expect {
          post season_weekends_path(season), params: valid_params, headers: auth_headers
        }.to change(Weekend, :count).by(1)
      end

      it 'redirects to the weekend' do
        post season_weekends_path(season), params: valid_params, headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, Weekend.last))
      end
    end
  end

  describe 'GET /seasons/:season_id/weekends/:id/edit' do
    let(:weekend) { create(:weekend, season: season) }

    it 'requires authentication' do
      get edit_season_weekend_path(season, weekend)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get edit_season_weekend_path(season, weekend), headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /seasons/:season_id/weekends/:id' do
    let(:weekend) { create(:weekend, season: season, gp_title: 'Old Title') }

    it 'requires authentication' do
      patch season_weekend_path(season, weekend), params: { weekend: { gp_title: 'New Title' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'updates the weekend' do
        patch season_weekend_path(season, weekend), params: { weekend: { gp_title: 'New Title' } }, headers: auth_headers
        expect(weekend.reload.gp_title).to eq('New Title')
      end

      it 'redirects to the weekend' do
        patch season_weekend_path(season, weekend), params: { weekend: { gp_title: 'New Title' } }, headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end
    end
  end

  describe 'DELETE /seasons/:season_id/weekends/:id' do
    let!(:weekend) { create(:weekend, season: season) }

    it 'requires authentication' do
      delete season_weekend_path(season, weekend)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'deletes the weekend' do
        expect {
          delete season_weekend_path(season, weekend), headers: auth_headers
        }.to change(Weekend, :count).by(-1)
      end

      it 'redirects to season' do
        delete season_weekend_path(season, weekend), headers: auth_headers
        expect(response).to redirect_to(season_path(season))
      end
    end
  end
end
