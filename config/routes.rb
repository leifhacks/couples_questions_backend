Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'auth/bootstrap', to: 'auth#bootstrap'
      post 'auth/refresh', to: 'auth#refresh'
      post 'auth/invalidate', to: 'auth#invalidate'
      post 'ios_multi_verification/verify', to: 'ios_multi_verification#verify'
      get 'images/down', to: 'images#down'
      get 'images/up', to: 'images#up'
    end
  end
end
