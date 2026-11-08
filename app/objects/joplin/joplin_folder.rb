class Obj::JoplinFolder < Obj
  type_sym :joplin_folder

  has_many :notes, :note, :joplin_folder_id, inverse_of: :joplin_folder

  def self.default_display
    {
      sym_sets: {
        default: [:id, :title]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        joplin_remote_id: { width: 35, type: :string, title: 'Joplin Remote ID' },
        title: { width: 20, type: :string, title: 'Title' },
      }
    }
  end

  def initialize(title, joplin_remote_id: nil)
    super(:joplin_folder, {title: title, joplin_remote_id: joplin_remote_id })
  end
end

