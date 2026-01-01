class Obj::Database
  attr_accessor :tag_context, :database_adapter, :database_adapter_class

  def self.database_adapter
    Obj::DatabaseAdapter::InMemoryDb
  end

  def self.migrate(all_migrations, database)
    database.database_adapter_class.migrate(all_migrations, database)
  end

  def self.rollback(all_migrations, database)
    database.database_adapter_class.rollback(all_migrations, database)
  end

  def self.create_table(table_name, attrs_and_types)
    database_adapter.create_table(table_name, attrs_and_types)
  end

  def self.load_or_reload(database, database_filename: nil)
    if database
      database.database_adapter_class.load_or_reload(database, database.database_adapter, database_filename)
    else
      database = self.new(database_adapter_class: database_adapter_for(database_filename),
                          database_filename: database_filename)
    end

    database
  end

  def self.database_adapter_for(database_filename)
    if database_filename =~ /\.sqlite3$/
      return Obj::DatabaseAdapter::SqliteDb
    elsif database_filename =~ /\.yml/
      return Obj::DatabaseAdapter::InMemoryDb
    else
      raise "invalid database type based on filename: #{database_filename}"
    end
  end

  def self.read
    database_adapter.read
  end

  def initialize(database_adapter_class: nil, database_filename: nil)
    @tag_context = 'tag'
    @database_adapter_class = database_adapter_class
    @database_adapter = @database_adapter_class.load_or_reload(self, @database_adapter, database_filename)
  end

  def info
    @database_adapter.info
  end

  def setup(setup_klass, db)
    self.class.migrate(setup_klass.migrations, db)
    setup_klass.classes.each {|klass| register_class(klass)}
  end

  def register_class(obj_class)
    Obj.register_class(obj_class)
    @database_adapter.register_class(obj_class)
  end


  def serialize
    @database_adapter.serialize
  end

  def deserialize(yml)
    @database_adapter.deserialize(yml)
  end

  def create_table(*args)
    @database_adapter.create_table(*args)
  end

  def drop_table(*args)
    @database_adapter.drop_table(*args)
  end

  def tag_context
    @tag_context
  end

  def unsaved?
    @database_adapter.unsaved?
  end

  def save
    @database_adapter.write
  end

  def objs
    @database_adapter.objs
  end

  def add_obj(obj, save_belongs_tos: true)
    @database_adapter.add_obj(obj, save_belongs_tos: save_belongs_tos)
  end

  def rem_obj(obj)
    @database_adapter.rem_obj(obj)
  end

  def update_obj(obj)
    @database_adapter.update_obj(obj)
  end

  def find_by(type_sym, finder_hash)
    @database_adapter.find_by(type_sym, finder_hash)
  end

  def inspect
    @database_adapter.inspect
  end

  def connect
    @database_adapter.connect
  end

  def disconnect
    @database_adapter.disconnect
  end

  def unlink
    @database_adapter.unlink
  end

  def migrations_applied
    @database_adapter.migrations_applied
  end

  def method_missing(sym, *args)
    if sym.to_s =~ /(.*)s/
      sym = $1.to_sym
    else
      return nil
    end

    @database_adapter.objs[sym]
  end
end
