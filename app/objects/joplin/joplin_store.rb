class Obj::JoplinStore < Obj::Store
  attr_reader :token
  def initialize(db, port: "41184", status_proc: ->(msg) { puts msg})
    super(status_proc: status_proc)
    @db = db
    @port = port
    @token = ENV['JOPLIN_TOKEN']
  end

  def sync
    # create or update local folders
    folders.each do |folder|
      db_folder = @db.find_by(:joplin_folder, { joplin_remote_id: folder.joplin_remote_id })
      if db_folder
        if db_folder.title != folder.title
          status_proc.call("Updating folder: #{folder.title}")
          db_folder.title = folder.title
          @db.update_obj(db_folder)
        end
      else
        # Create new folder
        status_proc.call("Creating folder: #{folder.title}")
        @db.add_obj(folder)
      end
    end

    # create or update local notes
    notes.each do |joplin_note|
      db_joplin_note = @db.find_by(:joplin_note, { joplin_remote_id: joplin_note.joplin_remote_id })
      db_folder = @db.find_by(:joplin_folder, { joplin_remote_id: joplin_note.joplin_folder_id })
      if db_joplin_note
        # Update existing note
        if !db_joplin_note.publish_only && (db_joplin_note.title != joplin_note.title || db_joplin_note.body != joplin_note.body)
          status_proc.call("Updating note: #{joplin_note.title}")
          db_joplin_note.title = joplin_note.title
          db_joplin_note.body = joplin_note.body
          db_joplin_note.joplin_folder_id = db_folder.db_id if db_folder
          @db.update_obj(db_joplin_note)

          db_note = db_joplin_note.note
          db_note.title = joplin_note.title
          db_note.body = joplin_note.body
          @db.update_obj(db_note)
        end
      else
        # Create new note
        status_proc.call("Creating joplin note: #{joplin_note.title}")
        db_joplin_note = @db.add_obj(joplin_note)
        if db_folder
          db_joplin_note.joplin_folder = db_folder
          @db.update_obj(db_joplin_note)
        end

        db_note = joplin_note.note
        if db_note
          # Update existing note
          if db_note.title != db_joplin_note.title || db_note.body != db_joplin_note.body
            status_proc.call("Updating note: #{db_note.title}")
            db_note.title = db_joplin_note.title
            db_note.body = db_joplin_note.body
            @db.update_obj(db_note)
          end
        else
          # Create new note
          status_proc.call("Creating note: #{db_joplin_note.title}")
          db_note = Obj::Note.new(db_joplin_note.title, db_joplin_note.body)
          @db.add_obj(db_note)
          db_joplin_note.note = db_note
          @db.update_obj(db_joplin_note)
        end
      end
    end

    # update publish_only notes
    @db.where_by(:joplin_note, { publish_only: true }).each do |db_joplin_note|
      unless db_joplin_note.joplin_remote_id.nil?
        status_proc.call("Updating note on Joplin: #{db_joplin_note.title}")
        update_note(db_joplin_note)
      end
    end

    # create remote notes
    @db.where_by(:joplin_note, { joplin_remote_id: nil }).each do |db_joplin_note|
      status_proc.call("Creating note on Joplin: #{db_joplin_note.title}")
      create_note(db_joplin_note)
      @db.update_obj(db_joplin_note)
    end


  end

  def notes(query: nil)
    notes = []
    page = 1
    while true
      resp = connection.get("/notes", { token: @token, fields: fields, limit: 100, page: page, order_by: 'updated_time', order_dir: 'ASC' })
      if resp.status == 200
        json = JSON.parse(resp.body)
        json["items"].each do |note_data|
          notes << new_note_from_joplin_data(note_data)
        end

        page += 1
        break unless json["has_more"]
      end
    end

    notes
  end

  def folders
    page = 1
    folders = []
    while true
      resp = connection.get("/folders", { token: @token, limit: 100, page: page  })
      if resp.status == 200
        json = JSON.parse(resp.body)
        json["items"].map do |folder_data|
          folders << Obj::JoplinFolder.new(
            folder_data["title"],
            joplin_remote_id: folder_data["id"])
        end

        page += 1
        break unless json["has_more"]
      else
        nil
      end
    end
    folders
  end

  def search_folder(name)
    resp = connection.get("/search", { type: 'folder', token: @token, query: name })
    if resp.status == 200
      JSON.parse(resp.body)["items"].map do |folder_data|
        Obj::JoplinFolder.new(
          folder_data["title"],
          joplin_remote_id: folder_data["id"]
        )
      end
    else
      []
    end
  end

  def search(query, type: 'note')
    query_tree = query.query_tree
    if query_tree.value == '==' && query_tree.left.value == :title && query_tree.right.value.is_a?(String)
      resp = connection.get("/search", { type: type, token: @token, query: query_tree.right.value, fields: fields })
      if resp.status == 200
        JSON.parse(resp.body)["items"].map do |note_data|
          new_note_from_joplin_data(note_data)
        end
      else
        []
      end
    else
      []
    end
  end

  def note(note_id)
    resp = connection.get("/notes/#{note_id}", { token: @token, fields: fields })
    if resp.status == 200
      note_data = JSON.parse(resp.body)
      new_note_from_joplin_data(note_data)
    else
      nil
    end
  end

  def create_note(note)
    resp = connection.post("/notes?token=#{@token}") do |req|
      req.body = { title: note.title, body: note.body, parent_id: note.joplin_folder.joplin_remote_id }.to_json
    end
    if resp.status == 200
      note_data = JSON.parse(resp.body)
      note.joplin_remote_id = note_data["id"]
      note
    else
      nil
    end
  end

  def update_note(note)
    resp = connection.put("/notes/#{note.joplin_remote_id}?token=#{@token}") do |req|
      req.body = { title: note.title, body: note.body, parent_id: note.joplin_folder.joplin_remote_id }.to_json
    end
    if resp.status == 200
      note_data = JSON.parse(resp.body)
    else
      nil
    end
  end

  private

  def new_note_from_joplin_data(note_data)
    jn = Obj::JoplinNote.new(
      note_data["title"],
      note_data["body"],
      joplin_remote_id: note_data["id"],
      joplin_folder_id: note_data["parent_id"]
    )
    jn
  end

  def connection
    Faraday.new(
      url: "http://localhost:#{@port}",
      headers: {'Content-Type' => 'application/json'}
    )
  end

  def fields
    'title,body,id,parent_id'
  end
end