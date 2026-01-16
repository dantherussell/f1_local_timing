require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:series) { create(:series) }

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

  describe 'GET /series/:series_id/sessions' do
    it 'returns JSON with sessions' do
      create(:session, series: series, name: 'Practice 1')
      create(:session, series: series, name: 'Qualifying')

      get series_sessions_path(series)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
      expect(json.map { |s| s['name'] }).to contain_exactly('Practice 1', 'Qualifying')
    end

    it 'only returns id and name fields' do
      create(:session, series: series, name: 'Race')

      get series_sessions_path(series)
      json = JSON.parse(response.body)

      expect(json.first.keys).to contain_exactly('id', 'name')
    end
  end

  describe 'GET /series/:series_id/sessions/new' do
    it 'requires authentication' do
      get new_series_session_path(series)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get new_series_session_path(series), headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /series/:series_id/sessions' do
    it 'requires authentication' do
      post series_sessions_path(series), params: { session: { name: 'Practice 1' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'creates a new session' do
        expect {
          post series_sessions_path(series), params: { session: { name: 'Practice 1' } }, headers: auth_headers
        }.to change(Session, :count).by(1)
      end

      it 'redirects to the series' do
        post series_sessions_path(series), params: { session: { name: 'Practice 1' } }, headers: auth_headers
        expect(response).to redirect_to(series_path(series))
      end

      it 'renders new with errors when create fails' do
        allow_any_instance_of(Session).to receive(:save).and_return(false)
        post series_sessions_path(series), params: { session: { name: 'Practice 1' } }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /series/:series_id/sessions/:id/edit' do
    let(:session_record) { create(:session, series: series) }

    it 'requires authentication' do
      get edit_series_session_path(series, session_record)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get edit_series_session_path(series, session_record), headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /series/:series_id/sessions/:id' do
    let(:session_record) { create(:session, series: series, name: 'Old Name') }

    it 'requires authentication' do
      patch series_session_path(series, session_record), params: { session: { name: 'New Name' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'updates the session' do
        patch series_session_path(series, session_record), params: { session: { name: 'New Name' } }, headers: auth_headers
        expect(session_record.reload.name).to eq('New Name')
      end

      it 'redirects to the series' do
        patch series_session_path(series, session_record), params: { session: { name: 'New Name' } }, headers: auth_headers
        expect(response).to redirect_to(series_path(series))
      end

      it 'renders edit with errors when update fails' do
        allow_any_instance_of(Session).to receive(:update).and_return(false)
        patch series_session_path(series, session_record), params: { session: { name: 'New Name' } }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /series/:series_id/sessions/:id' do
    let!(:session_record) { create(:session, series: series) }

    it 'requires authentication' do
      delete series_session_path(series, session_record)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'deletes the session' do
        expect {
          delete series_session_path(series, session_record), headers: auth_headers
        }.to change(Session, :count).by(-1)
      end

      it 'redirects to the series' do
        delete series_session_path(series, session_record), headers: auth_headers
        expect(response).to redirect_to(series_path(series))
      end
    end
  end
end
