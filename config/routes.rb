Rails.application.routes.draw do
  resources :transactions
  resources :accounts
  require 'sidekiq/web'
  # require 'sidecloq/web'
  # Ensure you have a valid session
  Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
  mount Sidekiq::Web => '/sidekiq'

  get 'bizs/update_measures', as: 'update_measures'
  get 'bizs/get_dimensions', as: 'get_dimensions'
  get 'bizs/update_dimensions', as: 'update_dimensions'
  get 'bizs/new_factors', as: 'new_factors'
  get 'bizs/preprocess', as: 'preprocess'

  post 'bizs/synchronize' => 'bizs#synchronize'

  # get 'bizs/:id/update_measures', as: 'update_measures'
  resources :bizs
  resources :sales
  resources :customers
  resources :products
  resources :salespeople

  root 'bizs#new'


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
