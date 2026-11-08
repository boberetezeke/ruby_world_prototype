class Obj::AddNoteMigration
  def self.up(database)
    database.create_table(
      :note,
      {
        joplin_remote_id: :string,
        joplin_folder_id: :integer,
        title: :string,
        body: :text
      }
    )
  end

  def self.down(database)
    database.drop_table(:note)
  end
end
