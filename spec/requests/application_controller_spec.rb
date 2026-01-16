require 'rails_helper'

RSpec.describe 'ApplicationController', type: :request do
  before do
    ENV['ADMIN_USERNAME'] = 'admin'
    ENV['ADMIN_PASSWORD'] = 'password'
  end

  describe 'theme switching' do
    it 'sets theme cookie and redirects when theme param is present' do
      get seasons_path, params: { theme: 'dark' }
      expect(response).to redirect_to(root_path)
      expect(cookies[:theme]).to eq('dark')
    end
  end

  describe 'authentication with wrong credentials' do
    it 'returns unauthorized when credentials are incorrect' do
      wrong_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('wrong', 'wrong')
      get new_season_path, headers: { 'HTTP_AUTHORIZATION' => wrong_credentials }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
