require 'rails_helper'

RSpec.describe 'Events', type: :request do
  let(:season) { create(:season) }
  let(:weekend) { create(:weekend, season: season) }
  let(:day) { weekend.days.first }
  let(:series) { create(:series) }
  let(:session_record) { create(:session, series: series) }

  before do
    ENV['ADMIN_USERNAME'] = 'admin'
    ENV['ADMIN_PASSWORD'] = 'password'
  end

  describe 'GET /seasons/:season_id/weekends/:weekend_id/days/:day_id/events/new' do
    it 'requires authentication' do
      get new_season_weekend_day_event_path(season, weekend, day)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get new_season_weekend_day_event_path(season, weekend, day), headers: auth_headers
      expect(response).to have_http_status(:success)
    end

    it 'loads all series for the form' do
      create(:series, name: 'Formula 1')
      create(:series, name: 'Formula 2')

      get new_season_weekend_day_event_path(season, weekend, day), headers: auth_headers
      expect(response.body).to include('Formula 1')
      expect(response.body).to include('Formula 2')
    end
  end

  describe 'POST /seasons/:season_id/weekends/:weekend_id/days/:day_id/events' do
    let(:valid_params) do
      {
        event: {
          racing_class: 'Formula 1',
          name: 'Race',
          start_time_time_field: '14:00',
          session_id: session_record.id
        }
      }
    end

    it 'requires authentication' do
      post season_weekend_day_events_path(season, weekend, day), params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'creates a new event' do
        expect {
          post season_weekend_day_events_path(season, weekend, day), params: valid_params, headers: auth_headers
        }.to change(Event, :count).by(1)
      end

      it 'redirects to the weekend' do
        post season_weekend_day_events_path(season, weekend, day), params: valid_params, headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end

      it 'converts time field to start_time' do
        post season_weekend_day_events_path(season, weekend, day), params: valid_params, headers: auth_headers
        event = Event.last
        expect(event.start_time.hour).to eq(14)
        expect(event.start_time.min).to eq(0)
      end

      it 'renders new with errors when create fails' do
        allow_any_instance_of(Event).to receive(:save).and_return(false)
        post season_weekend_day_events_path(season, weekend, day), params: valid_params, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /seasons/:season_id/weekends/:weekend_id/days/:day_id/events/:id/edit' do
    let(:event) { create(:event, day: day, session: session_record) }

    it 'requires authentication' do
      get edit_season_weekend_day_event_path(season, weekend, day, event)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get edit_season_weekend_day_event_path(season, weekend, day, event), headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /seasons/:season_id/weekends/:weekend_id/days/:day_id/events/:id' do
    let(:event) { create(:event, day: day, session: session_record, racing_class: 'Formula 1') }

    it 'requires authentication' do
      patch season_weekend_day_event_path(season, weekend, day, event), params: { event: { racing_class: 'Formula 2' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'updates the event' do
        patch season_weekend_day_event_path(season, weekend, day, event),
              params: { event: { racing_class: 'Formula 2' } },
              headers: auth_headers
        expect(event.reload.racing_class).to eq('Formula 2')
      end

      it 'redirects to the weekend' do
        patch season_weekend_day_event_path(season, weekend, day, event),
              params: { event: { racing_class: 'Formula 2' } },
              headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end

      it 'renders edit with errors when update fails' do
        allow_any_instance_of(Event).to receive(:update).and_return(false)
        patch season_weekend_day_event_path(season, weekend, day, event),
              params: { event: { racing_class: 'Formula 2' } },
              headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /seasons/:season_id/weekends/:weekend_id/days/:day_id/events/:id' do
    let!(:event) { create(:event, day: day, session: session_record) }

    it 'requires authentication' do
      delete season_weekend_day_event_path(season, weekend, day, event)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'deletes the event' do
        expect {
          delete season_weekend_day_event_path(season, weekend, day, event), headers: auth_headers
        }.to change(Event, :count).by(-1)
      end

      it 'redirects to the weekend' do
        delete season_weekend_day_event_path(season, weekend, day, event), headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end
    end
  end
end
