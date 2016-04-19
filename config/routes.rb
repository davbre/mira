require 'api_constraints'

Rails.application.routes.draw do

  devise_for :users
  root "projects#index"


  resources :user do
    resources :api_keys do
      resources :api_key_permissions
    end
  end

  get "users/:user_id/api_keys/:id/generate-new-api-key" => "api_keys#gen_new_key"

  # UI routes
  resources :projects do
    resources :datasources
    resource :datapackage do
      resources :datapackage_resources
    end
  end


  # custom project routes
  post "projects/:id/upload_datasources" => "projects#upload_datasources"
  post "projects/:id/upload_datapackage" => "projects#upload_datapackage"
  get "projects/:id/api-details" => "projects#api_detail"


  # API routes
  namespace :api, defaults: {format: 'json'} do
    # /api/... API::
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      # Projects
      get "projects" => "projects#index"
      get "projects/:id" => "projects#show"

      # Datapackage file
      get "projects/:id/datapackage" => "datapackages#show"

      # Datapackage resource metadata combined with some information from datasources (e.g. public_url)
      get "projects/:id/tables" => "datapackage_resources#index"
      get "projects/:id/tables/:table_ref" => "datapackage_resources#show"
      get "projects/:id/tables/:table_ref/columns" => "datapackage_resources#column_index"
      get "projects/:id/tables/:table_ref/columns/:col_ref" => "datapackage_resources#column_show"
      # Expose datapackage field metadata
      get "projects/:id/tables/:table_ref/datapackage/fields" => "datapackage_resource_fields#index"
      get "projects/:id/tables/:table_ref/datapackage/fields/:col_ref" => "datapackage_resource_fields#show"

      # Uploads (via datasources table)
      get "projects/:id/uploads" => "datasources#index"
      get "projects/:id/uploads/:table_ref" => "datasources#show"

      # Query data
      match "projects/:id/tables/:table_ref/data" => "data#datatables",
            :via => [:post],
            :constraints => lambda { |request| (request.params.has_key?(:draw) && request.params.has_key?(:start) && request.params.has_key?(:length)) }

      get "projects/:id/tables/:table_ref/data" => "data#index"
      get "projects/:id/tables/:table_ref/recline/data" => "data#recline"
      get ":db_table/metadata/search" => "data#index" # e.g. for searching project metadata
      # Distinct values
      get "projects/:id/tables/:table_ref/columns/:col_ref/distinct" => "data#distinct"

      # CRUD
      post "projects/:id/tables/:table_ref/data" => "data#create"
      get "projects/:id/tables/:table_ref/data/:data_id" => "data#show"
      patch "projects/:id/tables/:table_ref/data/:data_id" => "data#update"
      delete "projects/:id/tables/:table_ref/data/:data_id" => "data#destroy"
    end

  end

  # table = "xy41_97"
  # table_klass = ActiveRecord::Base.const_get "#{table}".capitalize
  # project_number, datasource_number = table.sub(Rails.configuration.x.db_table_prefix.downcase,"").split("_").map { |s| s.to_i }
  # table_ref = DatapackageResource.where(datasource_id: datasource_number).first.table_ref
  #
  # puts "Adding routes for project " + project_number.to_s + ", table " + table_ref
  # get_route =  "/api/projects/" + project_number.to_s + "/tables/" + table_ref + "/:id"
  # binding.pry
  # get get_route, :to => "projects#index"

end
