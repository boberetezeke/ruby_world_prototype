class Obj::Database
  attr_reader :objs, :version, :migrations_applied
  attr_reader :version_read

  # constants
  def self.original_version
    1
  end

  def self.current_version
    2
  end

  def self.migrations_applied_version
    2
  end

  attr_accessor :tag_context

  def initialize
    @objs = {}
    @classes = {}
    @migrations_applied = []
    @tag_context = 'tag'
  end

  def tag_context
    @tag_context
  end

  def self.db_yml_path
    File.join(ENV['RW_DATABASE_PATH'] || '.', 'db.yml')
  end

  def self.db_marshal_path
    File.join(ENV['RW_DATABASE_PATH'] || '.', 'db.mrs')
  end

  def serialize
    {
      version: self.class.current_version,
      objs: @objs,
      classes: @classes,
      migrations_applied: @migrations_applied
    }
  end

  def deserialize(yml)
    @version_read = yml[:version]
    @objs = yml[:objs]
    @classes = yml[:classes]
    @migrations_applied = yml[:version] >= self.class.migrations_applied_version ? yml[:migrations_applied] : []
  end

  def write
    serialize_data = serialize
    File.open(self.class.db_yml_path, "w") {|f| f.write(serialize_data.to_yaml) }
    File.open(self.class.db_marshal_path, "w") {|f| Marshal.dump(serialize_data, f) }
  end

  def add_migrations_applied(migrations)
    migrations.each{ |migration| @migrations_applied.push(migration) }
  end

  def self.migrate(all_migrations, database)
    database_backup = Marshal.dump(database)
    migrations_to_apply = (all_migrations - database.migrations_applied)
    migrations_to_apply.each do |migration|
      klass = eval(migration)
      begin
        puts "migrating: #{klass}"
        klass.up(database)
        puts "migration done: #{klass}"
      rescue StandardError => e
        puts "Migration: #{klass} failed, all new migrations cancelled"
        puts "ERROR: #{e}"
        e.backtrace[0..5].each do |bt|
          puts "  #{bt}"
        end
        return Marshal.load(database_backup)
      end
    end
    database.add_migrations_applied(migrations_to_apply)
    return database
  end

  def self.read
    database = self.new
    return database unless File.exist?(db_yml_path)

    serialized_data = File.open(db_marshal_path) { |f| Marshal.load(f) } if File.exist?(db_marshal_path)
    serialized_data ||= File.open(db_yml_path) { |f| YAML.load(f) }
    database.deserialize(serialized_data)
    database.reindex
    database = migrate(Migrations.migrations, database)
    database
  end

  def reindex
    reset_indexes
    index_objects
  end

  def reset_indexes
    @classes.each do |type_sym, klass|
      eval(klass).relationships.values.each do |relationship|
        relationship.reset_index
      end
    end
  end

  def index_objects
    @objs.each do |type_sym, objs|
      objs.each do |id, obj|
        obj.reset(type_sym, id, obj.attrs)
      end
    end
  end

  def add_obj(obj)
    class_name = obj.class.to_s
    @classes[obj.type_sym] = class_name
    objs_of_type = @objs[obj.type_sym] || {}
    @objs[obj.type_sym] = objs_of_type if @objs[obj.type_sym].nil?

    objs_of_type[obj.id] = obj
    obj
  end

  def rem_obj(obj)
    objs_of_type = @objs[obj.type_sym] || {}
    objs_of_type.delete(obj.id)
    obj
  end

  def where_by(type_sym, finder_hash)
    objs_of_type = @objs[type_sym] || {}
    objs_of_type.values.select do |obj|
      value_hash = finder_hash.keys.map{|key| [key, obj.send(key)]}.to_h
      value_hash == finder_hash
    end
  end

  def find_by(type_sym, finder_hash)
    where_by(type_sym, finder_hash).first
  end

  def inspect
    @objs.map{|k,v| [k, v.size]}
  end

  def method_missing(sym, *args)
    if sym.to_s =~ /(.*)s/
      sym = $1.to_sym
    else
      return nil
    end

    if @objs.keys.include?(sym)
      @objs[sym].values
    else
      nil
    end
  end
end
