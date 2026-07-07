Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"

  get    "login",        to: "sessions#new"
  post   "login",        to: "sessions#create"
  get    "login/verify", to: "sessions#new_code", as: :login_verify
  post   "login/verify", to: "sessions#verify_code"
  delete "logout",       to: "sessions#destroy"

  get    "dashboard",   to: "dashboard#show"
  post   "zips",        to: "zips#create"
  delete "zips/:code",  to: "zips#destroy", constraints: { code: /\d{5}/ }, as: :zip
  post   "bands",       to: "bands#create"
  delete "bands/:name", to: "bands#destroy", constraints: { name: /[^\/]+/ }, as: :band

  get "shows", to: "shows#index"
end
