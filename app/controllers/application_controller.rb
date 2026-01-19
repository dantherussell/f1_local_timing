class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_theme

  def test_auth
    session[:authed] = true
    head :ok
  end

  private

  def authenticate
    return if Rails.env.development?
    return if session[:authed]

    authenticate_or_request_with_http_basic do |username, password|
      if username == ENV["ADMIN_USERNAME"] && password == ENV["ADMIN_PASSWORD"]
        session[:authed] = true
        true
      else
        false
      end
    end
  end

  def set_theme
    if params[:theme].present?
      cookies[:theme] = params[:theme]
      redirect_to(request.referrer || root_path)
    end
  end
end
