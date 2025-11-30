class Obj
  module DatabaseAdapter
    class InMemoryDb
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

      def self.migrate(all_migrations, database)
        database_backup = Marshal.dump(database)
        migrations_to_apply = (all_migrations - database.migrations_applied)
        migrations_to_apply.each do |migration|
          klass = migration
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

      def self.rollback(all_migrations, database)
      end

      def self.db_path
        File.join(ENV['RW_DATABASE_PATH'] || '.', 'db.yml')
      end

      def self.load_or_reload(database)
        if database
          database.reindex
        else
          database = read(database)
          database.index_objects
        end
        database
      end

      def self.read(database)
        database_adapter = self.new(database)
        return database_adapter unless File.exist?(db_path)

        # TODO: replace unsafe_load with safe_load
        # YAML.safe_load_file(db_path, permitted_classes: [])
        yml = YAML.unsafe_load_file(db_path)
        database_adapter.deserialize(yml)
        database_adapter.reindex
        database_adapter = migrate(Migrations.migrations, database_adapter)
        database_adapter
      end

      def initialize(database)
        @database = database
        @objs = {}
        @classes = {}
        @migrations_applied = []
        @changes = []
      end

      def register_class(obj_class)
      end

      def unsaved?
        !@changes.empty?
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
        File.open(self.class.db_path, "w") {|f| f.write(serialize.to_yaml) }
        @changes = []
      end

      def info
      end

      def add_obj(obj, save_belongs_tos: nil)
        class_name = obj.class.to_s
        @classes[obj.type_sym] = class_name
        objs_of_type = @objs[obj.type_sym] || {}
        @objs[obj.type_sym] = objs_of_type if @objs[obj.type_sym].nil?
        @changes.push({change_type: :add_obj, obj: obj})
        obj.added_to_db(self)

        objs_of_type[obj.id] = obj
        obj
      end

      def rem_obj(obj)
        objs_of_type = @objs[obj.type_sym] || {}
        objs_of_type.delete(obj.id)
        obj
      end

      def update_obj(obj)
        return if obj.changes.empty?
        @changes.push({change_type: :update_obj, obj: obj})
      end

      def find_by(type_sym, finder_hash)
        objs_of_type = @objs[type_sym] || {}
        objs_of_type.values.select do |obj|
          value_hash = finder_hash.keys.map{|key| [key, obj.send(key)]}.to_h
          value_hash == finder_hash
        end.first
      end

      def get_objs(sym)
        if @objs.keys.include?(sym)
          @objs[sym].values
        else
          nil
        end
      end

      def connect
      end

      def disconnect
      end

      def create_table(*args)
      end

      def drop_table(*args)
      end

      def unlink
      end

      def add_migrations_applied(migrations)
        migrations.each{ |migration| @migrations_applied.push(migration) }
      end

      def inspect
        @objs.map{|k,v| [k, v.size]}
      end
    end
  end
end
