class Obj::AddTagMigration
  def self.up(database)
    database.create_table(
      :tag,
      {
        name: :string
      }
    )
  end

  def self.down(database)
    database.drop_table(:tag)
  end
end
