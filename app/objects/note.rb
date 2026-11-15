class Obj::Note < Obj
  type_sym :note

  has_one :joplin_note, :joplin_note, :joplin_note_id, inverse_of: :note

  def initialize(title, body)
    super(:note, {title: title, body: body})
  end

  def self.default_display
    {
      sym_sets: {
        default: [:id, :title, :body]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        joplin_remote_id: { width: 35, type: :string, title: 'Joplin Remote ID' },
        title: { width: 20, type: :string, title: 'Title' },
        body: { width: 20, type: :string, title: 'Body' },
      }
    }
  end

  def initialize(title, body, joplin_remote_id: nil, joplin_folder_id: nil)
    super(:note, {title: title, body: body, joplin_remote_id: joplin_remote_id, joplin_folder_id: joplin_folder_id})
  end
end

