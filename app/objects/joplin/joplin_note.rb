class Obj::JoplinNote < Obj
  type_sym :joplin_note

  belongs_to :joplin_folder, :joplin_folder_id, inverse_of: :notes
  belongs_to :note, :note_id, inverse_of: :joplin_note

  def self.default_display
    {
      sym_sets: {
        default: [:id, :title]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        joplin_remote_id: { width: 35, type: :string, title: 'Joplin Remote ID' },
        title: { width: 20, type: :string, title: 'Title' },
        body: { width: 50, type: :string, title: 'Body' },
        joplin_folder_id: { width: 35, type: :string, title: 'Joplin Folder ID' },
      }
    }
  end

  def initialize(title, body, joplin_remote_id: nil, joplin_folder_id: nil, note_id: nil)
    super(:joplin_note, {
      title: title,
      body: body,
      joplin_remote_id: joplin_remote_id,
      joplin_folder_id: joplin_folder_id,
      note_id: note_id,
      publish_only: false
    })
  end
end

