Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'auth/bootstrap', to: 'auth#bootstrap'
      post 'auth/refresh', to: 'auth#refresh'
      post 'auth/invalidate', to: 'auth#invalidate'
      put 'devices/:uuid', to: 'devices#update'
      get 'relationship', to: 'relationship#show'
      post 'relationship', to: 'relationship#update'
      post 'relationship/new_invite', to: 'relationship#new_invite'
      post 'relationship/unpair', to: 'relationship#unpair'
      post 'relationship/confirm_invite', to: 'relationship#confirm_invite'
      post 'relationship/redeem_invite', to: 'relationship#redeem_invite'
      get 'me', to: 'me#show'
      put 'me', to: 'me#update'
      post 'ios_multi_verification/verify', to: 'ios_multi_verification#verify'
      post 'images/up', to: 'images#up'
      get 'today_question', to: 'questions#today_question'
      get 'journal', to: 'questions#journal'
      put 'answers', to: 'answers#update'
      get 'categories', to: 'categories#index'
      get 'categories/:uuid/questions', to: 'categories#category_questions'
    end
  end
end
