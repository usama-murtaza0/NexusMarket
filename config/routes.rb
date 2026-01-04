Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  namespace :super_admin do
    resources :users
    root "dashboard#index"
    resources :dashboard, only: [:index]
    resources :tenants
  end

  namespace :shop_owner do
    resources :products
    resources :orders, only: [:index, :show]
  end

  namespace :customer do
    resources :products, only: [:index, :show]
    resources :orders, only: [:index, :show, :create]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
