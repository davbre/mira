

  # method to create dynamic activerecord class with all the scopes required for the API
  def load_dynamic_AR_class_with_scopes(table)

    if ActiveRecord::Base.const_defined? "#{table}".capitalize
      a_klass = ActiveRecord::Base.const_get "#{table}".capitalize
    else

      a_klass = Class.new ActiveRecord::Base do
        cattr_accessor :model_name
        self.abstract_class = false
        self.table_name = table # this is the existing table
        self.model_name = ActiveModel::Name.new(self, nil, table)
        # class_variable_set(:@@columns, self.columns_hash)
        # set inheritance_column to nil. See http://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html
        # If we don't do this, columns with the name "type" generate errors:
        #   "This error is raised because the column 'type' is reserved for storing the class in case of inheritance."
        self.inheritance_column = nil
      end

    end

    a_klass.class_eval do

      self.columns.each do |sc|

        sv = sc.name
        st = sc.cast_type.type

        # add validators
        if ["id"].exclude? sv
          if st == :integer
            self.validates sv.to_sym, numericality: { only_integer: true, :allow_nil => true }
          elsif [:float, :decimal].include? st
            self.validates sv.to_sym, numericality: {:allow_nil => true}
          end
          # TODO ?? validators for dates, datetimes, booleans ??

        end

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
          contains_scope = "scope :#{sv}_contains, -> (#{sv}) { where(\"#{sv} ilike ?\", \"%\#{#{sv}}%\") }"
          not_contains_scope = "scope :#{sv}_not_contains, -> (#{sv}) { where(\"#{sv} NOT ilike ?\", \"%\#{#{sv}}%\") }"
          begins_scope = "scope :#{sv}_begins, -> (#{sv}) { where(\"#{sv} ilike ?\", \"\#{#{sv}}%\") }"
          not_begins_scope = "scope :#{sv}_not_begins, -> (#{sv}) { where(\"#{sv} NOT ilike ?\", \"\#{#{sv}}%\") }"
          ends_scope = "scope :#{sv}_ends, -> (#{sv}) { where(\"#{sv} ilike ?\", \"%\#{#{sv}}\") }"
          not_ends_scope = "scope :#{sv}_not_ends, -> (#{sv}) { where(\"#{sv} NOT ilike ?\", \"%\#{#{sv}}\") }"
          text_blank_scope = "scope :#{sv}_blank, -> (#{sv}) { where(\"#{sv} = '' OR #{sv} IS NULL\") }"
          text_not_blank_scope = "scope :#{sv}_not_blank, -> (#{sv}) { where(\"#{sv} != '' AND #{sv} IS NOT NULL\") }"
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

    # only create class if it doesn't exist (e.g. the Project class will already exist)
    unless ActiveRecord::Base.const_defined? "#{table}".capitalize
      Object.const_set "#{table}".capitalize, a_klass
    end

  end
