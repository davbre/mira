class DatapackageResource < ActiveRecord::Base
  belongs_to :datapackage
  has_many :datapackage_resource_fields, dependent: :destroy
  has_many :datasources, dependent: :destroy
  validates :datapackage_id, presence: true
  validates :path, presence: true
  validates :delimiter, exclusion: {in: [nil]}, allow_blank: false # using this instead of presence: true as was unable to save "\t" (signifying tab-delimited)
  validates :quote_character, presence: true
  validates :table_ref, presence: true, uniqueness: { scope: :datapackage,
                                        message: "table_ref must be unique within a datapackage!" }


  def delete_db_table
    table = self.db_table_name
    if ActiveRecord::Base.connection.table_exists? table
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

end
