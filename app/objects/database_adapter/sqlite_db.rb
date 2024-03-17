require 'sequel'

class Obj
  module DatabaseAdapter
    class SqliteDb
      class Relation
        attr_reader :table_name
        def initialize(database, table_name)
          @database = database
          @table_name = table_name
        end

        def values
          all
        end

        def all
          @database.all(self).map do |attrs|
            Obj.new_from_db(@table_name, attrs)
          end
        end
      end

      class Tables
        def initialize(database)
          @database = database
        end

        def [](table_name)
          Relation.new(@database, table_name)
        end
      end

      def self.migrate(all_migrations, database)
        all_migrations.each do |migration|
          migration.up(database)
        end
      end

      def self.db_filename
        'test.sqlite'
      end

      def self.load_or_reload(database)
        new
      end

      def initialize
        @db = Sequel.connect("sqlite://#{self.class.db_filename}")
      end

      def create_table(table_name, columns)
        @db.create_table table_name do
          primary_key :id
          columns.each do |col_name, col_type|
            case col_type
            when :string
              String col_name
            when :float
              Float col_name
            when :integer
              Integer col_name
            end
          end
        end
      end

      def all(relation)
        @db[relation.table_name.to_sym].all
      end

      def objs
        Tables.new(self)
      end

      def unsaved?
        false
      end

      def reindex
      end

      def reset_indexes
      end

      def index_objects
      end

      def serialize
      end

      def deserialize(yml)
      end

      def write
      end

      def table(name)
        Relation.new(name)
      end

      def add_obj(obj)
        obj_table(obj).insert(obj.attrs)
      end

      def rem_obj(obj)
      end

      def update_obj(obj)
      end

      def find_by(type_sym, finder_hash)
      end

      def get_objs(sym)
      end

      def add_migrations_applied(migrations)
      end

      def inspect
      end

      def obj_table(obj)
        @db.from(obj.type_sym)
      end
    end
  end
end
