

  # method to create dynamic activerecord class with all the scopes required for the API
  def load_dynamic_AR_class_with_scopes(table)

    ds = Datasource.where(:db_table_name => "#{table}").first
    proj_name = Project.find(ds.project_id).name
    # logger.info("Project #{proj_name}: creating ActiveRecord class " + table +
    #      " which maps to " + ds.table_ref)

    new_klass = Class.new ActiveRecord::Base do
      cattr_accessor :model_name
      self.abstract_class = false
      self.table_name = table # this is the existing table
      self.model_name = ActiveModel::Name.new(self, nil, table)

      # class_variable_set(:@@columns, self.columns_hash)

      self.column_names.each do |sv|
        equals_scope = "scope :#{sv}, -> (#{sv}) { where #{sv}: #{sv} }"
        eval(equals_scope) # unless BANNED_COLUMN_NAMES.include? sv.downcase
        
        # if a text column then add a "contains" scope
        if ["text", "string"].include? self.columns_hash[sv].type.to_s
          contains_scope = "scope :#{sv}_contains, -> (#{sv}) { where(\"#{sv} like ?\", \"%\#{#{sv}}%\") }"
          not_contains_scope = "scope :#{sv}_not_contains, -> (#{sv}) { where(\"#{sv} NOT like ?\", \"%\#{#{sv}}%\") }"
          begins_scope = "scope :#{sv}_begins, -> (#{sv}) { where(\"#{sv} like ?\", \"\#{#{sv}}%\") }"
          begins_scope = "scope :#{sv}_begins, -> (#{sv}) { where(\"#{sv} NOT like ?\", \"\#{#{sv}}%\") }"
          ends_scope = "scope :#{sv}_ends, -> (#{sv}) { where(\"#{sv} like ?\", \"%\#{#{sv}}\") }"
          not_ends_scope = "scope :#{sv}_ends, -> (#{sv}) { where(\"#{sv} NOT like ?\", \"%\#{#{sv}}\") }"
          eval(contains_scope)
          eval(not_contains_scope)
          eval(begins_scope)
          eval(ends_scope)
        # else if numeric add greater than, less than filters
        elsif ["integer", "float", "decimal", "date", "time", "datetime", "timestamp"].include? self.columns_hash[sv].type.to_s
          lt_scope = "scope :#{sv}_lt, -> (#{sv}) { where(\"#{sv} < ?\",  \"\#{#{sv}}\") }"
          le_scope = "scope :#{sv}_le, -> (#{sv}) { where(\"#{sv} <= ?\", \"\#{#{sv}}\") }"
          gt_scope = "scope :#{sv}_gt, -> (#{sv}) { where(\"#{sv} > ?\",  \"\#{#{sv}}\") }"
          ge_scope = "scope :#{sv}_ge, -> (#{sv}) { where(\"#{sv} >= ?\", \"\#{#{sv}}\") }"
          eval(lt_scope)
          eval(le_scope)
          eval(gt_scope)
          eval(ge_scope)
        end
      end
    end
    
    Object.const_set "#{table}".capitalize, new_klass
  end
