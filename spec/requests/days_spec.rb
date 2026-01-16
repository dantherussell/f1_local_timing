require 'rails_helper'

RSpec.describe 'Days', type: :request do
  let(:season) { create(:season) }
  let(:weekend) { create(:weekend, season: season) }
  let(:day) { weekend.days.first }

  before do
    ENV['ADMIN_USERNAME'] = 'admin'
    ENV['ADMIN_PASSWORD'] = 'password'
  end

  describe 'GET /seasons/:season_id/weekends/:weekend_id/days/:id/edit' do
    it 'requires authentication' do
      get edit_season_weekend_day_path(season, weekend, day)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get edit_season_weekend_day_path(season, weekend, day), headers: auth_headers
      expect(response).to have_http_status(:success)
    end

    it 'displays the day formatted date' do
      get edit_season_weekend_day_path(season, weekend, day), headers: auth_headers
      expect(response.body).to include(day.formatted_date)
    end
  end

  describe 'PATCH /seasons/:season_id/weekends/:weekend_id/days/:id' do
    it 'requires authentication' do
      patch season_weekend_day_path(season, weekend, day), params: { day: { local_time_offset: '+03:00' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'updates the day' do
        patch season_weekend_day_path(season, weekend, day),
              params: { day: { local_time_offset: '+03:00' } },
              headers: auth_headers
        expect(day.reload.local_time_offset).to eq('+03:00')
      end

      it 'redirects to the weekend' do
        patch season_weekend_day_path(season, weekend, day),
              params: { day: { local_time_offset: '+03:00' } },
              headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end

      it 'renders edit with errors when update fails' do
        allow_any_instance_of(Day).to receive(:update).and_return(false)
        patch season_weekend_day_path(season, weekend, day),
              params: { day: { local_time_offset: '+03:00' } },
              headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /seasons/:season_id/weekends/:weekend_id/days/:id' do
    it 'requires authentication' do
      delete season_weekend_day_path(season, weekend, day)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'deletes the day' do
        day_to_delete = weekend.days.first
        expect {
          delete season_weekend_day_path(season, weekend, day_to_delete), headers: auth_headers
        }.to change(Day, :count).by(-1)
      end

      it 'cascades deletes to events' do
        session = create(:session)
        create(:event, day: day, session: session)

        expect {
          delete season_weekend_day_path(season, weekend, day), headers: auth_headers
        }.to change(Event, :count).by(-1)
      end

      it 'redirects to the weekend' do
        delete season_weekend_day_path(season, weekend, day), headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end
    end
  end
end
