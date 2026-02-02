require 'rails_helper'

RSpec.describe 'Weekends', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:season) { create(:season) }

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

    it 'displays events grouped by day' do
      session = create(:session)
      day1 = weekend.days.first
      day2 = weekend.days.second
      create(:event, day: day1, session: session, start_time: Time.parse('10:00'), name: 'FP1')
      create(:event, day: day2, session: session, start_time: Time.parse('14:00'), name: 'Qualifying')

      get season_weekend_path(season, weekend)
      expect(response).to have_http_status(:success)
    end

    context 'countdown timer' do
      let(:session) { create(:session) }

      it 'shows countdown when next event is within 24 hours' do
        travel_to Time.zone.local(2025, 6, 15, 12, 0, 0) do
          weekend = create(:weekend, season: season, first_day: Date.current, last_day: Date.current)
          day = weekend.days.first
          future_time = (Time.current + 2.hours).strftime('%H:%M')
          create(:event, day: day, session: session, start_time: Time.parse(future_time))

          get season_weekend_path(season, weekend)
          expect(response.body).to include('countdown')
          expect(response.body).to include('simply-countdown')
        end
      end

      it 'does not show countdown when next event is more than 24 hours away' do
        weekend = create(:weekend, season: season, first_day: Date.tomorrow + 1, last_day: Date.tomorrow + 1)
        day = weekend.days.first
        create(:event, day: day, session: session, start_time: Time.parse('14:00'))

        get season_weekend_path(season, weekend)
        expect(response.body).not_to include('simply-countdown')
      end

      it 'does not show countdown when all events are in the past' do
        weekend = create(:weekend, season: season, first_day: Date.yesterday, last_day: Date.yesterday)
        day = weekend.days.first
        create(:event, day: day, session: session, start_time: Time.parse('10:00'))

        get season_weekend_path(season, weekend)
        expect(response.body).not_to include('simply-countdown')
      end

      it 'does not show countdown when weekend has no events' do
        weekend = create(:weekend, season: season, first_day: Date.current, last_day: Date.current)

        get season_weekend_path(season, weekend)
        expect(response.body).not_to include('simply-countdown')
      end
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
          first_day: '2024-05-24',
          last_day: '2024-05-26',
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

      it 'renders new with errors when create fails' do
        allow_any_instance_of(Weekend).to receive(:save).and_return(false)
        post season_weekends_path(season), params: valid_params, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
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

      it 'renders edit with errors when update fails' do
        allow_any_instance_of(Weekend).to receive(:update).and_return(false)
        patch season_weekend_path(season, weekend), params: { weekend: { gp_title: 'New Title' } }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
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

  describe 'GET /seasons/:season_id/weekends/:id/import' do
    let(:weekend) { create(:weekend, season: season) }

    it 'requires authentication' do
      get import_season_weekend_path(season, weekend)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get import_season_weekend_path(season, weekend), headers: auth_headers
      expect(response).to have_http_status(:success)
    end

    it 'displays the import form' do
      get import_season_weekend_path(season, weekend), headers: auth_headers
      expect(response.body).to include('Import Schedule')
      expect(response.body).to include('Formula 1 Schedule URL')
    end
  end

  describe 'POST /seasons/:season_id/weekends/:id/import' do
    let(:weekend) { create(:weekend, season: season, first_day: Date.new(2025, 12, 5), last_day: Date.new(2025, 12, 7)) }
    let(:fixture_html) { File.read(Rails.root.join('spec/fixtures/f1_schedule_page.html')) }
    let(:f1_url) { 'https://www.formula1.com/en/latest/article/test-grand-prix-2025.abc123' }

    before do
      stub_request(:get, f1_url).to_return(status: 200, body: fixture_html)
    end

    it 'requires authentication' do
      post import_season_weekend_path(season, weekend), params: { url: f1_url }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'imports events from the URL' do
        expect {
          post import_season_weekend_path(season, weekend), params: { url: f1_url }, headers: auth_headers
        }.to change(Event, :count)
      end

      it 'redirects to weekend page on success' do
        post import_season_weekend_path(season, weekend), params: { url: f1_url }, headers: auth_headers
        expect(response).to redirect_to(season_weekend_path(season, weekend))
      end

      it 'shows success notice' do
        post import_season_weekend_path(season, weekend), params: { url: f1_url }, headers: auth_headers
        expect(flash[:notice]).to include('Successfully imported')
      end

      context 'when URL is blank' do
        it 'shows an error' do
          post import_season_weekend_path(season, weekend), params: { url: '' }, headers: auth_headers
          expect(response.body).to include('Please provide a URL')
        end
      end

      context 'when fetch fails' do
        before do
          stub_request(:get, f1_url).to_return(status: 404)
        end

        it 'shows an error' do
          post import_season_weekend_path(season, weekend), params: { url: f1_url }, headers: auth_headers
          expect(response.body).to include('Failed to fetch page')
        end
      end

      context 'when import fails' do
        before do
          allow_any_instance_of(F1ScheduleImporter).to receive(:call)
            .and_return(Result.failure("Database error"))
        end

        it 'shows the importer error' do
          post import_season_weekend_path(season, weekend), params: { url: f1_url }, headers: auth_headers
          expect(response.body).to include('Database error')
        end
      end
    end
  end
end
