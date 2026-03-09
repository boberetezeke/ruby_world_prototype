def db_type_mem(&)
  context 'With db_type mem' do
    let(:db_type_class) {  Obj::DatabaseAdapter::InMemoryDb }

    before do
      ENV['db_type'] = 'mem'
      ENV['db_type_filename'] = 'test_db.yml'
    end
  end.class_eval(&)
end


def db_type_sqlite(&)
  context 'With db_type sqlite' do
    let(:db_type_class) {  Obj::DatabaseAdapter::SqliteDb }

    before do
      ENV['db_type'] = 'sqlite'
      ENV['db_type_filename'] = 'test2_db.sqlite3'
    end
  end.class_eval(&)
end

def db_type_all(&)
  db_type_mem(&)
  db_type_sqlite(&)
end
