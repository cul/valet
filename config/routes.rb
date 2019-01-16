Rails.application.routes.draw do
  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  root 'welcome#index'
  get 'welcome/index'
  get 'welcome/logout'

  get '/timeout', to: 'welcome#timeout'

  devise_for :users, controllers: { sessions: 'users/sessions', omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    get 'sign_in', to: 'users/sessions#new', as: :new_user_session
    get 'sign_out', to: 'users/sessions#destroy', as: :destroy_user_session
  end

  # Valet maps all these requests to the Forms Controller,
  # with each path mapping to a key in app_config.yml
  # - incoming links to /docdel/123 map to #show, with bibkey 123,
  # - #show method builds a form based on bibkey 123 which posts to #create,
  # - #create, the form-handler - logs, emails, bounces, etc.
  # resources :borrowdirect,
  resources :ill,
            :docdel,
            :intercampus,
            :inprocess,
            :precat,
            :itemfeedback,
            :notonshelf,
            :bearstor,
            controller: 'forms',
            only: [:show, :create]

  resources :borrowdirect, only: [:show]
  resources :recall_hold, only: [:show]

  # ILL currently has custom code
  # Offsite currently has custom code
  # 'Barnard' currently has custom code

  resources :ill_requests do
    collection do
      get 'affiliation'
      get 'bib'
      get 'ineligible'
      get 'error'
    end
  end

  resources :offsite_requests do
    collection do
      # different entry points to the request workflow
      get 'bib'
      get 'holding'
      get 'barcode'

      # exception conditions
      get 'ineligible'
      get 'error'
    end
  end

  # resources :barnard_remote_requests do
  #   collection do
  #     # different entry points to the request workflow
  #     get 'bib'
  #     get 'holding'
  #
  #     # exception conditions
  #     get 'ineligible'
  #     get 'error'
  #   end
  # end

  # special admin pages
  get 'admin/system'
  get 'admin/logs'
  get 'admin/log_file'

  # all requests generate logs
  resources :logs do
    collection do
      # bounce the user to another URL, and log it
      get 'bounce'
      # # List known log sets
      # get 'sets'
    end
  end
end
