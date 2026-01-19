Rails.application.routes.draw do
  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "seasons#index"
  get "auth" => "seasons#auth"

  resources :seasons do
    resources :weekends, except: [ :index ] do
      get "print", on: :member
      resources :days, only: [ :edit, :update, :destroy ] do
        resources :events, except: [ :index, :show ]
      end
    end
  end

  resources :series do
    resources :sessions, except: [ :show ]
  end
end
