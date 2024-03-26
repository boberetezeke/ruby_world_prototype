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
        @type_sym_to_sequel_class = {}
        @sequel_class_to_type_sym = {}
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
        Relation.new(@db, name)
      end

      def add_obj(obj)
        r = obj_table(obj).insert(obj.attrs)
        r
      end

      def rem_obj(obj)
      end

      def update_obj(obj)
      end

      def find_by(type_sym, finder_hash)
        klass = type_sym_to_sequel_class(type_sym)
        objs = klass.where(finder_hash)
        objs.map { |obj| wrap_obj(obj) }
      end

      def register_class(obj_class)
        sequel_class = create_sequel_class(obj_class)
        @type_sym_to_sequel_class[obj_class.type_sym] = sequel_class
        @sequel_class_to_type_sym[sequel_class.to_s] = obj_class.type_sym
      end

      def create_sequel_class(klass)
        str = sequel_class_str(klass)
        eval(str)
      end

      def sequel_class_str(klass)
        s = klass.to_s.split(/::/)
        class_name = "Sequel#{s[1]}"
        type_sym = klass.get_type_sym
        rels = klass.relationships.map do |_sym, rel|
          case rel.rel_type
          when :belongs_to
            "many_to_one :sequel_#{rel.name}, key: :#{rel.foreign_key}"
          when :has_many
            "one_to_many :sequel_#{rel.name}, key: :#{rel.foreign_key}"
          end
        end

        "class " + class_name + " < Sequel::Model(:#{type_sym});" + rels.join(";") + ";end"
      end

      def type_sym_to_sequel_class(type_sym)
        @classes[type_sym]
      end

      def wrap_obj(sequel_obj)
        Obj.classes[obj.type_sym].allocate
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
