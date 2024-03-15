require 'sequel'

module Obj
  module DatabaseAdapter
    class SqliteDb
      def initialize
        @db = Sequel.connect('sqlite://test.sqlite')
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

      def add_obj(obj)
        obj_table(obj).insert(obj.attributes)
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
