require 'rails_helper'

RSpec.describe 'Events', type: :request do
  let(:season) { create(:season) }
  let(:weekend) { create(:weekend, season: season) }
  let(:series) { create(:series) }
  let(:session_record) { create(:session, series: series) }

  before do
    ENV['ADMIN_USERNAME'] = 'admin'
    ENV['ADMIN_PASSWORD'] = 'password'
  end

  describe 'GET /seasons/:season_id/weekends/:weekend_id/events/new' do
    it 'requires authentication' do
      get new_season_weekend_event_path(season, weekend)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get new_season_weekend_event_path(season, weekend), headers: auth_headers
      expect(response).to have_http_status(:success)
    end

    it 'loads all series for the form' do
      create(:series, name: 'Formula 1')
      create(:series, name: 'Formula 2')

      get new_season_weekend_event_path(season, weekend), headers: auth_headers
      expect(response.body).to include('Formula 1')
      expect(response.body).to include('Formula 2')
    end
  end

  describe 'POST /seasons/:season_id/weekends/:weekend_id/events' do
    let(:valid_params) do
      {
        event: {
          racing_class: 'Formula 1',
          name: 'Race',
          start_time_date_field: '2024-05-26',
          start_time_time_field: '14:00',
          session_id: session_record.id
        }
      }
    end

    it 'requires authentication' do
      post season_weekend_events_path(season, weekend), params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'creates a new event' do
        expect {
          post season_weekend_events_path(season, weekend), params: valid_params, headers: auth_headers
        }.to change(Event, :count).by(1)
      end

      it 'redirects to the weekend' do
        post season_weekend_events_path(season, weekend), params: valid_params, headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end

      it 'converts date and time fields to start_time' do
        post season_weekend_events_path(season, weekend), params: valid_params, headers: auth_headers
        event = Event.last
        expect(event.start_time.year).to eq(2024)
        expect(event.start_time.month).to eq(5)
        expect(event.start_time.day).to eq(26)
        expect(event.start_time.hour).to eq(14)
      end
    end
  end

  describe 'GET /seasons/:season_id/weekends/:weekend_id/events/:id/edit' do
    let(:event) { create(:event, weekend: weekend, session: session_record) }

    it 'requires authentication' do
      get edit_season_weekend_event_path(season, weekend, event)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get edit_season_weekend_event_path(season, weekend, event), headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /seasons/:season_id/weekends/:weekend_id/events/:id' do
    let(:event) { create(:event, weekend: weekend, session: session_record, racing_class: 'Formula 1') }

    it 'requires authentication' do
      patch season_weekend_event_path(season, weekend, event), params: { event: { racing_class: 'Formula 2' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'updates the event' do
        patch season_weekend_event_path(season, weekend, event),
              params: { event: { racing_class: 'Formula 2' } },
              headers: auth_headers
        expect(event.reload.racing_class).to eq('Formula 2')
      end

      it 'redirects to the weekend' do
        patch season_weekend_event_path(season, weekend, event),
              params: { event: { racing_class: 'Formula 2' } },
              headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end
    end
  end

  describe 'DELETE /seasons/:season_id/weekends/:weekend_id/events/:id' do
    let!(:event) { create(:event, weekend: weekend, session: session_record) }

    it 'requires authentication' do
      delete season_weekend_event_path(season, weekend, event)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'deletes the event' do
        expect {
          delete season_weekend_event_path(season, weekend, event), headers: auth_headers
        }.to change(Event, :count).by(-1)
      end

      it 'redirects to the weekend' do
        delete season_weekend_event_path(season, weekend, event), headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end
    end
  end
end
