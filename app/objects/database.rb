class Obj::Database
  attr_reader :objs, :tags, :migrations_applied

  def initialize
    @objs = {}
    @tags = {}
    @migrations_applied = []

    # constants
    @original_version = 1
    @current_version = 2
    @migrations_applied_version = 2
  end

  def self.db_path
    ENV['RW_DATABASE_PATH'] || 'db.yml'
  end

  def serialize
    {
      version: @current_version,
      objs: @objs,
      tags: @tags,
      migrations_applied: @migrations_applied
    }
  end

  def deserialize(yml)
    @objs = yml[:objs]
    @tags = yml[:tags]
    @migrations_applied = yml[:version] >= @migrations_applied_version ? yml[:migrations_applied] : []
  end

  def write
    File.open(self.class.db_path, "w") {|f| f.write(serialize.to_yaml) }
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
    return database unless File.exist?(db_path)

    yml = File.open(db_path) { |f| YAML.load(f) }
    database.deserialize(yml)
    database = migrate(Migrations.migrations, database)
    database
  end

  def add_obj(obj)
    objs_of_type = @objs[obj.type_sym] || {}
    @objs[obj.type_sym] = objs_of_type if @objs[obj.type_sym].nil?

    objs_of_type[obj.id] = obj
    obj
  end

  def find_by(type_sym, finder_hash)
    objs_of_type = @objs[type_sym] || {}
    objs_of_type.values.select do |obj|
      value_hash = finder_hash.keys.map{|key| [key, obj.send(key)]}.to_h
      value_hash == finder_hash
    end.first
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
