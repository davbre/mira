# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

ActiveRecord::SchemaDumper.ignore_tables = [ /^#{Rails.configuration.x.db_table_prefix.downcase}/ ]