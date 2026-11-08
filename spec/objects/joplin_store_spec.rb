require_relative '../../app/objects'
require_relative '../../app/migrations'
require_relative '../support/database_support'
require 'json'

describe Obj::JoplinStore do
  let(:db_type_class) { Obj::DatabaseAdapter::SqliteDb }
  context 'db_type_all' do
    describe '#sync' do
      let(:db_test_filename) { 'test.sqlite3' }
      let(:db) { Obj::Database.new(database_adapter_class: db_type_class, filename: db_test_filename) }
      subject { described_class.new(db, status_proc: ->(msg) { }) }

      before do
        allow(Obj::Database).to receive(:database_adapter).and_return(Obj::DatabaseAdapter::SqliteDb)
        # allow(Obj::Database).to receive(:database_adapter).and_return(Obj::DatabaseAdapter::InMemoryDb)
        db.connect
        Obj::Database.migrate(Obj::Setup.migrations, db)
        Obj::Setup.register_classes(db, Obj::Setup.classes)
      end

      after do
        Obj::Database.rollback(Obj::Setup.migrations, db)
      end

      let(:folder_items) do
        [
          { id: 'folder-1', title: 'Folder 1' },
          { id: 'folder-2', title: 'Folder 2' },
        ]
      end

      let(:note_items) do
        [
          { id: 'note-1', title: 'Note 1', body: 'This is the body of Note 1', parent_id: 'folder-1' },
          { id: 'note-2', title: 'Note 2', body: 'This is the body of Note 2', parent_id: 'folder-1' },
          { id: 'note-3', title: 'Note 3', body: 'This is the body of Note 3', parent_id: 'folder-2' },
        ]
      end

      let(:connection) { double(:connection) }

      context 'when building the notes and folders from joplin API' do
        before do
          allow(subject).to receive(:connection).and_return(connection)
          allow(connection).to receive(:get).with('/folders', { token: subject.token, limit: 100, page: 1 }).and_return(
            double('response', status: 200, body: { items: folder_items, has_more: false }.to_json)
          )
          allow(connection).to receive(:get).with(
            '/notes',
            {
              token: subject.token,
              fields: 'title,body,id,parent_id',
              limit: 100,
              page: 1,
              order_by: 'updated_time',
              order_dir: 'ASC'
            }).and_return(
            double('response', status: 200, body: { items: note_items, has_more: false }.to_json)
          )

          subject.sync
        end

        it 'creates the correct number of notes' do
          expect(db.objs[:note].size).to eq(3)
        end

        it 'creates the correct number of joplin notes' do
          expect(db.objs[:joplin_note].size).to eq(3)
        end

        it 'creates the correct number of folders' do
          expect(db.objs[:joplin_folder].size).to eq(2)
        end

        it 'attaches note and folder to joplin note' do
          db_joplin_note = db.objs[:joplin_note].find_by(joplin_remote_id: 'note-1')
          expect(db_joplin_note.title).to eq('Note 1')
          expect(db_joplin_note.body).to eq('This is the body of Note 1')
          expect(db_joplin_note.note.title).to eq('Note 1')
          expect(db_joplin_note.note.body).to eq('This is the body of Note 1')
          expect(db_joplin_note.joplin_folder.title).to eq('Folder 1')
        end
      end

      context 'when updating the notes from joplin API' do
        before do
          allow(subject).to receive(:connection).and_return(connection)
          allow(connection).to receive(:get).with('/folders', { token: subject.token, limit: 100, page: 1 }).and_return(
            double('response', status: 200, body: { items: folder_items, has_more: false }.to_json)
          )
          allow(connection).to receive(:get).with(
            '/notes',
            {
              token: subject.token,
              fields: 'title,body,id,parent_id',
              limit: 100,
              page: 1,
              order_by: 'updated_time',
              order_dir: 'ASC'
            }).and_return(
            double('response', status: 200, body: { items: note_items, has_more: false }.to_json)
          )

          joplin_note_1 = Obj::JoplinNote.new('Old Note 1', 'This is the old body of Note 1', joplin_remote_id: 'note-1', joplin_folder_id: 'folder-1')
          joplin_note_1.note = Obj::Note.new('Old Note 1', 'This is the old body of Note 1')
          joplin_note_1.joplin_folder = Obj::JoplinFolder.new('Old Folder 1', joplin_remote_id: 'folder-1')
          db.add_obj(joplin_note_1)

          joplin_note_2 = Obj::JoplinNote.new('Old Note 2', 'This is the old body of Note 2', joplin_remote_id: 'note-2', joplin_folder_id: 'folder-2')
          joplin_note_2.publish_only = true
          joplin_note_2.note = Obj::Note.new('Old Note 2', 'This is the old body of Note 2')
          joplin_note_2.joplin_folder = Obj::JoplinFolder.new('Old Folder 2', joplin_remote_id: 'folder-2')
          db.add_obj(joplin_note_2)

          expect(connection).to receive(:put).with("/notes/note-2?token=#{subject.token}").and_return(
            double('response', status: 200, body: { id: 'note-2' }.to_json)
          )

          subject.sync
        end

        it 'creates the correct number of notes' do
          expect(db.objs[:note].size).to eq(3)
        end

        it 'creates the correct number of joplin notes' do
          expect(db.objs[:joplin_note].size).to eq(3)
        end

        it 'creates the correct number of folders' do
          expect(db.objs[:joplin_folder].size).to eq(2)
        end

        it 'updates the title and body of the joplin note if not publish only' do
          db_joplin_note = db.objs[:joplin_note].find_by(joplin_remote_id: 'note-1')
          expect(db_joplin_note.title).to eq('Note 1')
          expect(db_joplin_note.body).to eq('This is the body of Note 1')
          expect(db_joplin_note.note.title).to eq('Note 1')
          expect(db_joplin_note.note.body).to eq('This is the body of Note 1')
          expect(db_joplin_note.joplin_folder.title).to eq('Folder 1')
        end

        it 'doesnt update the title and body of the joplin note if publish only' do
          db_joplin_note = db.objs[:joplin_note].find_by(joplin_remote_id: 'note-2')
          expect(db_joplin_note.title).to eq('Old Note 2')
          expect(db_joplin_note.body).to eq('This is the old body of Note 2')
          expect(db_joplin_note.note.title).to eq('Old Note 2')
          expect(db_joplin_note.note.body).to eq('This is the old body of Note 2')
        end
      end

      context 'when building the notes and folders to the joplin API' do
        before do
          allow(subject).to receive(:connection).and_return(connection)
          allow(connection).to receive(:get).with('/folders', { token: subject.token, limit: 100, page: 1 }).and_return(
            double('response', status: 200, body: { items: folder_items, has_more: false }.to_json)
          )
          allow(connection).to receive(:get).with(
            '/notes',
            {
              token: subject.token,
              fields: 'title,body,id,parent_id',
              limit: 100,
              page: 1,
              order_by: 'updated_time',
              order_dir: 'ASC'
            }).and_return(
            double('response', status: 200, body: { items: [], has_more: false }.to_json)
          )
        end

        context 'when adding new notes to Joplin' do
          before do
            db_joplin_folder = Obj::JoplinFolder.new('Folder 1', joplin_remote_id: 'folder-1')
            db.add_obj(db_joplin_folder)
            db_joplin_note = Obj::JoplinNote.new('Note 1', 'This is the body of Note 1')
            db_joplin_note.joplin_folder = db_joplin_folder
            db.add_obj(db_joplin_note)
            db_joplin_note_2 = Obj::JoplinNote.new('Note 2', 'This is the body of Note 2')
            db_joplin_note_2.joplin_folder = db_joplin_folder
            db.add_obj(db_joplin_note_2)
          end

          it 'creates notes on Joplin' do
            post_bodies = []
            allow(connection).to receive(:post) do |_url, &request_block|
              request = Struct.new(:body).new
              request_block.call(request)
              post_bodies << JSON.parse(request.body, symbolize_names: true)
              double('response', status: 200, body: { id: 'note-1' }.to_json)
            end

            subject.sync

            expect(connection).to have_received(:post).with(
              "/notes?token=#{subject.token}"
            ).twice
            expect(post_bodies).to contain_exactly(
              { title: 'Note 1', body: 'This is the body of Note 1', parent_id: 'folder-1' },
              { title: 'Note 2', body: 'This is the body of Note 2', parent_id: 'folder-1' }
            )
          end
        end

        context 'when updating existing notes on Joplin' do
          before do
            db_joplin_folder = Obj::JoplinFolder.new('Folder 1', joplin_remote_id: 'folder-1')
            db.add_obj(db_joplin_folder)
            db_joplin_note = Obj::JoplinNote.new('Note 1', 'This is the body of Note 1', joplin_remote_id: 'note-1')
            db_joplin_note.publish_only = true
            db_joplin_note.joplin_folder = db_joplin_folder
            db.add_obj(db_joplin_note)
            db_joplin_note_2 = Obj::JoplinNote.new('Note 2', 'This is the body of Note 2', joplin_remote_id: 'note-2')
            db_joplin_note_2.publish_only = true
            db_joplin_note_2.joplin_folder = db_joplin_folder
            db.add_obj(db_joplin_note_2)
          end

          it 'updates notes on Joplin' do
            put_bodies = []
            allow(connection).to receive(:put) do |_url, &request_block|
              request = Struct.new(:body).new
              request_block.call(request)
              put_bodies << JSON.parse(request.body, symbolize_names: true)
              double('response', status: 200, body: { id: 'note-1' }.to_json)
            end

            subject.sync

            expect(connection).to have_received(:put).with(
              "/notes/note-1?token=#{subject.token}"
            ).once
            expect(connection).to have_received(:put).with(
              "/notes/note-2?token=#{subject.token}"
            ).once
            expect(put_bodies).to contain_exactly(
                                     { title: 'Note 1', body: 'This is the body of Note 1', parent_id: 'folder-1' },
                                     { title: 'Note 2', body: 'This is the body of Note 2', parent_id: 'folder-1' }
                                   )
          end
        end
      end
    end
  end
end
