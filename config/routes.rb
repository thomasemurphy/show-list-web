Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"

  # The public pages that used to be the showlist.live GitHub Pages site.
  # Rails's implicit (.:format) suffix means /privacy.html and /terms.html
  # still resolve here, so the URLs registered with Twilio for A2P 10DLC keep
  # working unchanged.
  get "about",   to: "pages#about"
  get "privacy", to: "pages#privacy"
  get "terms",   to: "pages#terms"
  # The old site's home page is now /about.
  get "index",   to: redirect("/about")

  get    "login",          to: "sessions#new"
  post   "login",          to: "sessions#create"
  get    "login/verify",   to: "sessions#new_code", as: :login_verify
  post   "login/verify",   to: "sessions#verify_code"
  get    "login/password", to: "sessions#new_password", as: :login_password
  post   "login/password", to: "sessions#create_with_password"
  delete "logout",         to: "sessions#destroy"

  get    "dashboard",       to: "dashboard#show"
  get    "settings",        to: "settings#show"
  patch  "settings/password", to: "settings#update_password", as: :settings_password
  patch  "settings/notifications", to: "settings#update_notifications", as: :settings_notifications
  post   "zips",        to: "zips#create"
  patch  "zips/reorder", to: "zips#reorder", as: :reorder_zips
  delete "zips/:code",  to: "zips#destroy", constraints: { code: /\d{5}/ }, as: :zip
  post   "bands",       to: "bands#create"
  patch  "bands/reorder", to: "bands#reorder", as: :reorder_bands
  delete "bands/:name", to: "bands#destroy", constraints: { name: /[^\/]+/ }, as: :band

  get "shows", to: "shows#index"
end
