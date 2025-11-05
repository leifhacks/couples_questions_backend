Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :ios_multi_verification do
        collection do
          post 'verify'
        end
      end
      resources :images do
        collection do
          get 'down'
          get 'up'
        end
      end
    end
  end
end
