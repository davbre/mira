
require 'load_dynamic_AR_class_with_scopes'


# Prior to a migration the project table does not exist. Without checking
# for it, it causes errors during an initial migration (i.e. create, migrate),
# because you are referring to a table not yet created!
if ActiveRecord::Base.connection.table_exists? 'projects'

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

end

# map datapackage types to activerecord types
DATAPACKAGE_TYPE_MAP = {
    "boolean" => "boolean",
    "integer" => "integer",
    "number" => "float",
    "float" => "float",
    "geopoint" => "float",     # seen in airport-codes dataset although have not found any documentation for it!
    "datetime" => "datetime",
    "date" => "date",
    "time" => "time",
    "string" => "text",
    "null" => "text"
  }

BIG_INTEGER_LIMIT = 2147483647 # 2^31-1
