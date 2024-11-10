class Obj::Database
  attr_accessor :tag_context

  def self.database_adapter
    Obj::DatabaseAdapter::InMemoryDb
  end

  def self.migrate(all_migrations, database)
    database_adapter.migrate(all_migrations, database)
  end

  def self.rollback(all_migrations, database)
    database_adapter.rollback(all_migrations, database)
  end

  def self.create_table(table_name, attrs_and_types)
    database_adapter.create_table(table_name, attrs_and_types)
  end

  def self.load_or_reload(database)
    database_adapter.load_or_reload(database)
  end

  def self.read
    database_adapter.read
  end

  def initialize
    @tag_context = 'tag'
    @database_adapter = self.class.database_adapter.new(self)
  end

  def info
    @database_adapter.info
  end

  def register_class(obj_class)
    Obj.register_class(obj_class)
    @database_adapter.register_class(obj_class)
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

    @database_adapter.get_objs(sym)
  end
end
