class Obj::AddJoplinObjectsMigration
  def self.up(database)
    database.create_table(
      :joplin_folder,
      {
        joplin_remote_id: :string,
        title: :string,
      }
    )

    database.create_table(
      :joplin_note,
      {
        joplin_remote_id: :string,
        joplin_folder_id: :integer,
        publish_only: :boolean,
        note_id: :integer,
        title: :string,
        body: :string,
      }
    )
  end

  def self.down(database)
    database.drop_table(:joplin_folder)
    database.drop_table(:joplin_note)
  end
end
