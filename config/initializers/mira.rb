
require 'load_dynamic_AR_class_with_scopes'


extra_table_prefix = Rails.application.config.x.db_table_prefix.downcase
extra_tables = ActiveRecord::Base.connection.tables.select { |a| a.starts_with?(extra_table_prefix) }

# Create a model for each of the data tables
extra_tables.each do |table|

  load_dynamic_AR_class_with_scopes(table)

end
