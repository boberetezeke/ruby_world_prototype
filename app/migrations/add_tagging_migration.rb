class Obj::AddTaggingMigration
  def self.up(database)
    database.create_table(
      :tagging,
      {
        taggable_id: :integer,
        taggable_type: :string,
        tag_id: :integer
      }
    )
  end

  def self.down(database)
    database.drop_table(:tagging)
  end
end
