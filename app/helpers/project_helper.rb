module ProjectHelper

  def datapackage_errors
    @datapackage_errors = {
      already_uploaded: "A datapackage already exists for this project.",
      no_upload: "You must upload a datapackage.json file.",
      bad_json: "Failed to parse datapackage.json.",
      resources_missing: "datapackage.json must contain a 'resources' array.",
      resources_not_array: "datapackage.json must contain a 'resources' array.",
      resources_empty: "datapackage.json must contain a non-empty 'resources' array.",
      resource_not_hash: "resource metadata must be a hash.",
      missing_path: "Each resource must have a path.",
      missing_schema: "Each resource must have a schema.",
      path_not_string: "Resource path must be a String, e.g. 'mydata.csv'",
      path_empty: "Resource 'path' is empty.",
      path_not_csv: "Resource 'path' should refer to a csv file.",
      schemas_missing: "Expected a 'schemas' hash as 'schema' string is given.",
      schema_not_hash: "Resource 'schema' must be a Hash.",
      schema_no_fields: "Resource 'schema' must contain 'fields'.",
      schema_not_array: "Resource schema 'fields' must be an Array.",
      field_not_name_and_type: "Each resource schema field must contain 'name' and 'type' keys.",
      field_invalid_name: "Field name is not valid.",
      field_invalid_type: "Field type is not valid.",
      delimiter_too_long: "Delimiter character must be a single character.",
      quote_char_too_long: "Quote character must be a single character."
    }
  end

  def datasource_errors
    @datasource_errors = {
      no_upload: "You must upload one or more csv files.",
      no_datapackage: "This project has no associated datapackage.",
      missing_resource_metadata: "This project's datapackage has no resource metadata.",
      non_csv: "Only csv files can be uploaded.",
      already_uploaded: "A file of this name has been uploaded already",
      no_resource_metadata: "This project's datapackage has no metadata for uploaded file.",
      field_missing_metadata: "This project's datapackage has metadata for the uploaded file but none for its fields."
    }
  end

  def add_path_to_feedback(resource)
    @feedback[:errors] << "Path: " + resource["path"].to_s + "."
  end

  def add_field_to_feedback(field)
    @feedback[:errors] << "Field: " + field.to_s + "."
  end

  def extract_schema(json_dp,resource)
    # at this point we know that the resource has a "schema"
    if resource["schema"].class == Hash
      schema = resource["schema"]
    elsif resource["schema"].class == String
      if resource["schema"].empty?
        @feedback[:errors] << "Resource schema is empty! (Resource " + resource["path"] + ")"
      elsif !json_dp.has_key? "schemas"
        @feedback[:errors] << datapackage_errors[:schemas_missing]
      elsif !json_dp["schemas"][resource["schema"]]
        @feedback[:errors] << "The " + resource["schema"] + " is not present in the datapackage's 'schemas' object."
      else
        schema = json_dp["schemas"][resource["schema"]]
      end
    end
    schema
  end

  def check_and_clean_datapackage(dp)
    dp_path = dp.tempfile.path
    dp_file = File.read(dp_path)
    json_dp = {}
    begin
      json_dp = JSON.parse(dp_file)
    rescue => e
      @feedback[:errors] << datapackage_errors[:bad_json]
    else
      @feedback[:errors] << datapackage_errors[:resources_missing] if !json_dp.has_key? "resources"
      @feedback[:errors] << datapackage_errors[:resources_not_array] if (json_dp.has_key? "resources") && (json_dp["resources"].class != Array)
      @feedback[:errors] << datapackage_errors[:resources_empty] if (json_dp.has_key? "resources") && (json_dp["resources"].empty?)
    end

    json_dp = trim_datapackage(json_dp)

    if @feedback[:errors].empty?

      json_dp["resources"].each do |resource|
        @feedback[:errors] << datapackage_errors[:resource_not_hash] if resource.class != Hash
        @feedback[:errors] << datapackage_errors[:missing_path] if !resource.has_key? "path"
        @feedback[:errors] << datapackage_errors[:missing_schema] if !resource.has_key? "schema"
        if resource.has_key? "path"
          extension = (resource["path"].to_s.split("/").last.to_s.split(".").length > 1) ? resource["path"].to_s.split("/").last.to_s.split(".").last.downcase : ""
          if resource["path"].class != String
            @feedback[:errors] << datapackage_errors[:path_not_string]
            add_path_to_feedback resource
          elsif [nil, ""].include? resource["path"]
            @feedback[:errors] << datapackage_errors[:path_empty]
            add_path_to_feedback resource
          elsif extension != "csv"
            @feedback[:errors] << datapackage_errors[:path_not_csv]
            add_path_to_feedback resource
          end
        end

        if resource.has_key? "path" and resource.has_key? "schema"

          # keep only the filename in "path"
          resource["path"] = resource["path"].split("/").last if resource.has_key? "path" and resource["path"].class == String

          schema = extract_schema(json_dp,resource)

          if schema.class != Hash
            @feedback[:errors] << datapackage_errors[:schema_not_hash]
            add_path_to_feedback resource
          elsif !schema.has_key? "fields"
            @feedback[:errors] << datapackage_errors[:schema_no_fields]
            add_path_to_feedback resource
          elsif schema["fields"].class != Array
            @feedback[:errors] << datapackage_errors[:schema_not_array]
            add_path_to_feedback resource
          else
            schema["fields"].each do |field|
              if not (field.has_key? "name" and field.has_key? "type")
                @feedback[:errors] << datapackage_errors[:field_not_name_and_type]
                add_path_to_feedback resource
                add_field_to_feedback field
              else
                if (field["name"].parameterize.underscore =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) == nil
                  @feedback[:errors] << datapackage_errors[:field_invalid_name]
                  add_path_to_feedback resource
                  add_field_to_feedback field
                end
                unless DATAPACKAGE_TYPE_MAP.keys.include? field["type"].downcase
                  @feedback[:errors] << datapackage_errors[:field_invalid_type]
                  add_path_to_feedback resource
                  add_field_to_feedback field
                  @feedback[:errors] << "Valid types are " + DATAPACKAGE_TYPE_MAP.keys.join(", ") + "."
                end
              end
            end
          end
        end
      end
    end
    json_dp
  end


  def extract_and_save_datapackage_resources(dp_object,json_dp)
    json_dp["resources"].each do |res|
      dp_res = DatapackageResource.new(datapackage_id: dp_object.id, path: res["path"], table_ref: File.basename(res["path"],".*"))
      dp_res.format = res["format"] if res.has_key? "format"
      dp_res.mediatype = res["mediatype"] if res.has_key? "mediatype"
      dp_res.description = res["description"].to_s if res.has_key? "description"
      # delimiter
      delimiter = ','
      if res.has_key? "dialect" and res["dialect"].has_key? "delimiter"
        dlm_len = res["dialect"]["delimiter"].length
        if dlm_len > 1
          @feedback[:errors] << datapackage_errors[:delimiter_too_long]
        elsif dlm_len != 0
          delimiter = res["dialect"]["delimiter"]
        end
      else
        @feedback[:notes] << "datapackage.json does not specify a delimiter character so it defaults to a comma."
      end
      dp_res.delimiter = delimiter
      # quote character
      qchar = '"'
      if res.has_key? "dialect" and res["dialect"].has_key? "quote"
        qchar_len = res["dialect"]["quote"].length
        if qchar_len > 1
          @feedback[:errors] << datapackage_errors[:quote_char_too_long]
        elsif qchar_len != 0
          qchar = res["dialect"]["quote"]
        end
      else
        @feedback[:notes] << "datapackage.json does not specify a quote character so it defaults to a double quote."
      end
      dp_res.quote_character = qchar

      if dp_res.valid? && @feedback[:errors].empty?
        dp_res.save
        extract_and_save_resource_fields(json_dp,dp_res)
      else
        @feedback[:errors] << "Datapackage resource not saved for " + res["path"] + ". ERRORS: " + dp_res.errors.to_a.join(", ") + "."
      end
    end
  end


  def create_dp_db_tables(datapackage)
    dp_resources = DatapackageResource.where(datapackage_id: datapackage.id)
    dp_resources.each do |res|
      create_table_for_resource(res)
      res.db_table_name = Rails.configuration.x.db_table_prefix.downcase + datapackage.project_id.to_s + "_" + res.id.to_s
      res.save
    end
  end


  def create_table_for_resource(resource)
    column_metadata = DatapackageResourceField.where(datapackage_resource_id: resource.id)
    create_table_options = column_metadata.map { |a| a.name }.exclude?("id") ? {} : {id: false}
    dp_project_id = Datapackage.find(resource.datapackage_id).project_id
    db_table_name = Rails.configuration.x.db_table_prefix.downcase + dp_project_id.to_s + "_" + resource.id.to_s
    ActiveRecord::Base.connection.create_table(db_table_name.to_sym, create_table_options) do |t|
      column_metadata.each do |col|
        # The following mimics what is seen in migrations, e.g.:
        #   t.string :name
        #   t.text   :description
        # Cater for big integers
        col_name = new_col_name(col.name)
        if DATAPACKAGE_TYPE_MAP[col.ftype] == "date" && col.format.to_s.downcase == "yyyy"
          t.send "integer", col_name
        elsif DATAPACKAGE_TYPE_MAP[col.ftype] == "integer" && col.big_integer == true
          t.send DATAPACKAGE_TYPE_MAP[col.ftype], col_name, :limit => 8
        else
          t.send DATAPACKAGE_TYPE_MAP[col.ftype], col_name
        end
      end
    end

    # Add an index for each column
    column_metadata.each do |col|
      if col.add_index
        if col.ftype == "string"
          # create case insensitive index. Don't think the add_index method can be used so used a raw query.
          # http://www.postgresql.org/docs/9.1/static/sql-createindex.html
          new_col_name = new_col_name(col.name)
          create_index_execute_string = "CREATE INDEX index_" + db_table_name + "_on_" + new_col_name + " ON \"" + db_table_name + "\" (lower(\"" + new_col_name + "\"))"
          ActiveRecord::Base.connection.execute(create_index_execute_string)
        else
          ActiveRecord::Base.connection.add_index db_table_name.to_sym, new_col_name(col.name)
        end
      end
    end
  end


  def new_col_name(name)
    name.parameterize.underscore
  end


  def open_read_api(datapackage)
    dp_resources = DatapackageResource.where(datapackage_id: datapackage.id)
    dp_resources.each do |res|
      load_dynamic_AR_class_with_scopes(res.db_table_name)
    end
  end


  def extract_and_save_resource_fields(json_dp,resource)
    feedback = { errors: [], warnings: [], notes: []}
    json_resource = json_dp["resources"].find{ |r| r["path"] == resource.path }
    resource_schema = extract_schema(json_dp,json_resource)
    # resource_schema = json_dp["resources"].find{ |r| r["path"] == resource.path }["schema"]
    resource_schema["fields"].each_with_index do |field,ndx|
      res_field = DatapackageResourceField.new(datapackage_resource_id: resource.id, name: field["name"], ftype: field["type"], order: ndx + 1)
      if field["constraints"].present?
        field_min = custom_is_string_int?(field["constraints"]["minimum"]) ? field["constraints"]["minimum"].to_i : 0
        field_max = custom_is_string_int?(field["constraints"]["maximum"]) ? field["constraints"]["maximum"].to_i : 0
        res_field.big_integer = true if [field_min.abs, field_max.abs].max > BIG_INTEGER_LIMIT
      end
      if field["mira"].present?
        if field["mira"]["index"].to_s.present?
          if field["mira"]["index"].to_s.downcase.to_sym == :false
            res_field.add_index = false
          else
            res_field.add_index = true
          end
        end
        if field["mira"]["private"].to_s.present?
          if field["mira"]["private"].to_s.downcase.to_sym == :true
            res_field.private = true
          else
            res_field.private = false
          end
        end
      end
      if field["format"].present?
        res_field.format = field["format"].to_s
      end
      res_field.save
    end
  end


  def check_datasources
    if @datapackage.nil?
      @feedback[:errors] << datasource_errors[:no_datapackage]
    elsif @csv_uploads.nil? || @csv_uploads.empty?
      @feedback[:errors] << datasource_errors[:no_upload]
    elsif @datapackage.datapackage_resources.nil?
      @feedback[:errors] << datasource_errors[:missing_resource_metadata]
    else
      datasource_filenames = @csv_uploads.map { |u| u.original_filename }
      datapackage_filenames = @datapackage.datapackage_resources.map { |ds| ds.path }
      existing_uploads = @project.datasources.map { |ds| ds.datafile_file_name }
      @csv_uploads.each do |csv|
        if csv.original_filename !~ /\.csv/i
          @feedback[:errors] << datasource_errors[:non_csv]
          @feedback[:errors] << "Upload: " + csv.original_filename + "."
        elsif datapackage_filenames.exclude? csv.original_filename
          @feedback[:errors] << datasource_errors[:no_resource_metadata]
          @feedback[:errors] << "Upload: " + csv.original_filename + "."
        elsif existing_uploads.include? csv.original_filename
          @feedback[:errors] << datasource_errors[:already_uploaded]
          @feedback[:errors] << "Upload: " + csv.original_filename + "."
        else
          dp_res = @datapackage.datapackage_resources.where(path: csv.original_filename).first
          dp_res_fields = dp_res.datapackage_resource_fields
          if dp_res_fields.empty?
            # shouldn't ever reach here...but just in case
            @feedback[:errors] << datasource_errors[:field_missing_metadata]
            @feedback[:errors] << "Upload: " + csv.original_filename
          else
            # At this point we know we have metadata for all uploaded files (via
            # the processing of the uploaded datapackage.json file).
            # Do a quick check of each csv file.
            dp_res_fields = dp_res.datapackage_resource_fields
            csv_actual_fields = CSV.open(csv.tempfile, 'r', {:col_sep => dp_res.delimiter}) { |csvfile| csvfile.first }.sort
            csv_metadata_fields = dp_res_fields.map { |f| f.name }.sort
            if csv_actual_fields != csv_metadata_fields
              @feedback[:errors] << "The datapackage.json field names for " + csv.original_filename +
                                    " do not match the fields in the csv file. Expected: [" +
                                    csv_metadata_fields.join(", ") + "]. Actual: [" + csv_actual_fields.join(", ") + "]."
            end
          end
        end
      end
    end
  end


  def save_datapackage(dp)
    dp.save # save first...then can get public url
    dp.public_url = dp.datapackage.url.partition("?").first
    dp.save
  end


  def trim_datapackage(json_dp)
    # remove all datapackage.json keys which are not needed (e.g. README). Doing this here
    # because embedded html spooks the server. It detects content-spoofing and getting the
    # error "Datapackage has contents that are not what they are reported to be"
    json_dp.each do |k,v|
      if !["name","title","description","resources","schemas"].include? k
        @feedback[:notes] << "Trimming '" + k + "' attribute from datapackage.json"
        json_dp.delete(k)
      end
    end
    json_dp
  end


  def save_datasource(csv)
    csv_file = File.open(csv.tempfile.path)
    ds = @project.datasources.create(datafile: csv_file, datafile_file_name: csv.original_filename, datapackage_id: @datapackage.id) # ds = datasource
    if ds.valid?
      ds.public_url = ds.datafile.url.partition("?").first
    else
      @feedback[:errors] << "Failed to create datasource. Errors: " + ds.errors.to_a.join(", ")
    end
    retval = ds.save ? ds : nil
    retval
  end


end
