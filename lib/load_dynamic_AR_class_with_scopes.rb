

  # method to create dynamic activerecord class with all the scopes required for the API
  def load_dynamic_AR_class_with_scopes(table)

    ds = Datasource.where(:db_table_name => "#{table}").first

    if ds.nil?
      return nil
    else
      proj_name = Project.find(ds.project_id).name
    end

    # logger.info("Project #{proj_name}: creating ActiveRecord class " + table +
    #      " which maps to " + ds.table_ref)

    new_klass = Class.new ActiveRecord::Base do
      cattr_accessor :model_name
      self.abstract_class = false
      self.table_name = table # this is the existing table
      self.model_name = ActiveModel::Name.new(self, nil, table)
      # class_variable_set(:@@columns, self.columns_hash)
      # set inheritance_column to nil. See http://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html
      # If we don't do this, columns with the name "type" generate errors:
      #   "This error is raised because the column 'type' is reserved for storing the class in case of inheritance."
      self.inheritance_column = nil

      # http://stackoverflow.com/a/7202438/1002140
      # added before_save callback as sometimes empty strings were being saved as ""
      # and other times as NULL, depending on the quoting character
      before_save :normalize_blank_values

      def normalize_blank_values
        attributes.each do |column, value|
          self[column].present? || self[column] = nil
        end
      end

      self.column_names.each do |sv|


        # !! NB: when a new scope is added, update data_controller, specifically the datatables section!!
        # using "_eq" suffix as without it we run the risk of conflicting with existing methods, e.g. "name", "time" etc.
        equals_scope = "scope :#{sv}_eq, -> (#{sv}) { where #{sv}: #{sv} }"
        not_equals_scope = "scope :#{sv}_ne, -> (#{sv}) { where.not #{sv}: #{sv} }"
        eval(equals_scope)
        eval(not_equals_scope)

        unless ["boolean"].include? self.columns_hash[sv].type.to_s
          lt_scope = "scope :#{sv}_lt, -> (#{sv}) { where(\"#{sv} < ?\",  \"\#{#{sv}}\") }"
          le_scope = "scope :#{sv}_le, -> (#{sv}) { where(\"#{sv} <= ?\", \"\#{#{sv}}\") }"
          gt_scope = "scope :#{sv}_gt, -> (#{sv}) { where(\"#{sv} > ?\",  \"\#{#{sv}}\") }"
          ge_scope = "scope :#{sv}_ge, -> (#{sv}) { where(\"#{sv} >= ?\", \"\#{#{sv}}\") }"
          eval(lt_scope)
          eval(le_scope)
          eval(gt_scope)
          eval(ge_scope)
        end

        # if a text column then add a "contains" scope
        if ["text", "string"].include? self.columns_hash[sv].type.to_s
          contains_scope = "scope :#{sv}_contains, -> (#{sv}) { where(\"#{sv} like ?\", \"%\#{#{sv}}%\") }"
          not_contains_scope = "scope :#{sv}_not_contains, -> (#{sv}) { where(\"#{sv} NOT like ?\", \"%\#{#{sv}}%\") }"
          begins_scope = "scope :#{sv}_begins, -> (#{sv}) { where(\"#{sv} like ?\", \"\#{#{sv}}%\") }"
          not_begins_scope = "scope :#{sv}_not_begins, -> (#{sv}) { where(\"#{sv} NOT like ?\", \"\#{#{sv}}%\") }"
          ends_scope = "scope :#{sv}_ends, -> (#{sv}) { where(\"#{sv} like ?\", \"%\#{#{sv}}\") }"
          not_ends_scope = "scope :#{sv}_not_ends, -> (#{sv}) { where(\"#{sv} NOT like ?\", \"%\#{#{sv}}\") }"
          text_blank_scope = "scope :#{sv}_blank, -> (#{sv}) { where #{sv}: nil }"
          text_not_blank_scope = "scope :#{sv}_not_blank, -> (#{sv}) { where.not #{sv}: nil }"
          eval(contains_scope)
          eval(not_contains_scope)
          eval(begins_scope)
          eval(not_begins_scope)
          eval(ends_scope)
          eval(not_ends_scope)
          eval(text_blank_scope)
          eval(text_not_blank_scope)
          # distinct values method...(note, this is not a scope). This is used for the "distinct" routes (see data controller)
          eval("def self.#{sv}_uniq; self.uniq.pluck(:#{sv}); end;")
        elsif ["integer", "float", "decimal", "date", "time", "datetime", "timestamp", "boolean"].include? self.columns_hash[sv].type.to_s
          non_text_blank_scope = "scope :#{sv}_blank, -> (#{sv}) { where #{sv}: nil }"
          non_text_not_blank_scope = "scope :#{sv}_not_blank, -> (#{sv}) { where.not #{sv}: nil }"
          eval(non_text_blank_scope)
          eval(non_text_not_blank_scope)
        end

      end

    end

    Object.const_set "#{table}".capitalize, new_klass
  end
