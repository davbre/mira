
module ApplicationHelper

  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = "Mira"
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end


  # http://stackoverflow.com/questions/6672244/convert-ruby-string-to-nix-filename-compatible-string
  def friendly_filename(filename)
      filename.gsub(/[^\w\s_-]+/, '')
              .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
              .gsub(/\s+/, '_')
  end

  #http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
  def is_number? string
    true if Float(string) rescue false
  end


  def get_mira_ar_table(table) # table is a string
    begin
      ar_table = Mira::Application.const_get(table.capitalize)
    rescue NameError => e
      load_dynamic_AR_class_with_scopes(table)
    end
  end


  def custom_is_string_int?(str) # http://stackoverflow.com/a/1235990/1002140
     /\A[-+]?\d+\z/ === str
  end


  def bootstrap_class_for(flash_type)
    case flash_type
      when "success"
        "alert-success"   # Green
      when "error"
        "alert-danger"    # Red
      when "alert"
        "alert-warning"   # Yellow
      when "notice"
        "alert-info"      # Blue
      else
        flash_type.to_s
    end
  end

end
