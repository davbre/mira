
require 'load_dynamic_AR_class_with_scopes'


valid_project_prefixes = Project.ids.map do |id|
  Rails.application.config.x.db_table_prefix.downcase + id.to_s + "_"
end

api_tables = ActiveRecord::Base.connection.tables.select { |a|
  valid_project_prefixes.any? { |z| a.starts_with? z}
}

# Create a model for each of the data tables
api_tables.each do |table|

  load_dynamic_AR_class_with_scopes(table)

end
