class Obj::Database
  attr_accessor :tag_context

  def self.database_adapter
    Obj::DatabaseAdapter::InMemoryDb
  end

  def self.migrate(all_migrations, database)
    database_adapter.migrate(all_migrations, database)
  end

  def self.load_or_reload(database)
    database_adapter.load_or_reload(database)
  end

  def initialize
    @tag_context = 'tag'
    @database_adapter = self.class.database_adapter.new
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

  def add_obj(obj)
    @database_adapter.add_obj(obj)
  end

  def rem_obj(obj)
    @database_adapter.rem_obj(obj)
  end

  def update_obj(obj)
    @database_adapter.save_obj(obj)
  end

  def find_by(type_sym, finder_hash)
    @database_adapter.find_by(type_sym, finder_hash)
  end

  def inspect
    @database_adapter.inspect
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
