def db_type_mem(&)
  let(:db_type_class) {  Obj::DatabaseAdapter::InMemoryDb }
  let(:db_test_filename) { 'test.yml' }

  context 'With db_type mem' do
    before do
      ENV['db_type'] = 'mem'
    end
  end.class_eval(&)
end


def db_type_sqlite(&)
  let(:db_type_class) {  Obj::DatabaseAdapter::SqliteDb }
  let(:db_test_filename) { 'test.sqlite3' }

  context 'With db_type sqlite' do
    before do
      ENV['db_type'] = 'sqlite'
    end
  end.class_eval(&)
end

def db_type_all(&)
  db_type_mem(&)
  db_type_sqlite(&)
end
