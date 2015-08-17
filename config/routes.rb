require 'api_constraints'

Rails.application.routes.draw do

  devise_for :users
  root "projects#index"

  # UI routes  
  resources :projects
  # custom project routes
  post "projects/:id/upload_ds" => "projects#upload_ds"
  get "projects/:id/api-details" => "projects#api_detail"


  # API routes
  namespace :api, defaults: {format: 'json'} do
    # /api/... API::
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      # Projects
      get "projects" => "projects#index"
      get "projects/:id" => "projects#show"
      # Data sources
      get "projects/:id/tables" => "datasources#index"
      get "projects/:id/tables/:table_ref" => "datasources#show"
      get "projects/:id/tables/:table_ref/columns" => "datasources#column_index"
      get "projects/:id/tables/:table_ref/columns/:col_ref" => "datasources#column_show"

      # Data
      match "projects/:id/tables/:table_ref/data" => "data#datatables",
            :via => [:post],
            :constraints => lambda { |request| (request.params.has_key?(:draw) && request.params.has_key?(:start) && request.params.has_key?(:length)) }

      get "projects/:id/tables/:table_ref/data" => "data#index"

      # Distinct values
      get "projects/:id/tables/:table_ref/columns/:col_ref/distinct" => "data#distinct"
    end

  end

end