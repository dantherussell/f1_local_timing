require 'rails_helper'

RSpec.describe 'Series', type: :request do
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

  describe 'GET /series' do
    it 'requires authentication' do
      get series_index_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get series_index_path, headers: auth_headers
      expect(response).to have_http_status(:success)
    end

    it 'displays all series when authenticated' do
      create(:series, name: 'Formula 1')
      create(:series, name: 'Formula 2')

      get series_index_path, headers: auth_headers
      expect(response.body).to include('Formula 1')
      expect(response.body).to include('Formula 2')
    end
  end

  describe 'GET /series/:id' do
    let(:series) { create(:series) }

    it 'requires authentication' do
      get series_path(series)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get series_path(series), headers: auth_headers
      expect(response).to have_http_status(:success)
    end

    it 'displays series sessions' do
      create(:session, series: series, name: 'Practice 1')
      create(:session, series: series, name: 'Qualifying')

      get series_path(series), headers: auth_headers
      expect(response.body).to include('Practice 1')
      expect(response.body).to include('Qualifying')
    end
  end

  describe 'GET /series/new' do
    it 'requires authentication' do
      get new_series_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get new_series_path, headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /series' do
    it 'requires authentication' do
      post series_index_path, params: { series: { name: 'Formula 1' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'creates a new series' do
        expect {
          post series_index_path, params: { series: { name: 'Formula 1' } }, headers: auth_headers
        }.to change(Series, :count).by(1)
      end

      it 'redirects to series index' do
        post series_index_path, params: { series: { name: 'Formula 1' } }, headers: auth_headers
        expect(response).to redirect_to(series_index_path)
      end

      it 'renders new with errors when create fails' do
        allow_any_instance_of(Series).to receive(:save).and_return(false)
        post series_index_path, params: { series: { name: 'Formula 1' } }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /series/:id/edit' do
    let(:series) { create(:series) }

    it 'requires authentication' do
      get edit_series_path(series)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a successful response when authenticated' do
      get edit_series_path(series), headers: auth_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /series/:id' do
    let(:series) { create(:series, name: 'Old Name') }

    it 'requires authentication' do
      patch series_path(series), params: { series: { name: 'New Name' } }
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'updates the series' do
        patch series_path(series), params: { series: { name: 'New Name' } }, headers: auth_headers
        expect(series.reload.name).to eq('New Name')
      end

      it 'redirects to the series' do
        patch series_path(series), params: { series: { name: 'New Name' } }, headers: auth_headers
        expect(response).to redirect_to(series_path(series))
      end

      it 'renders edit with errors when update fails' do
        allow_any_instance_of(Series).to receive(:update).and_return(false)
        patch series_path(series), params: { series: { name: 'New Name' } }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /series/:id' do
    let!(:series) { create(:series) }

    it 'requires authentication' do
      delete series_path(series)
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      it 'deletes the series' do
        expect {
          delete series_path(series), headers: auth_headers
        }.to change(Series, :count).by(-1)
      end

      it 'redirects to series index' do
        delete series_path(series), headers: auth_headers
        expect(response).to redirect_to(series_index_path)
      end
    end
  end
end
