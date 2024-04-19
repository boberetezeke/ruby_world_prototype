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

        def size
          values.size
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

      def self.rollback(all_migrations, database)
        all_migrations.each do |migration|
          migration.down(database)
        end
      end

      def self.db_filename
        'test.sqlite'
      end

      def self.load_or_reload(database)
        new(database)
      end

      attr_reader :db

      def initialize(database)
        @database = database
        @type_sym_to_sequel_class = {}
        @sequel_class_to_type_sym = {}
      end

      def info
        @db[:credit_card].to_a.each do |credit_card|
          puts "credit_card: #{credit_card}"
        end
        @db[:vendor].to_a.each do |vendor|
          puts "vendor: #{vendor}"
        end
        @db[:charge].to_a.each do |charge|
          puts "charge: #{charge}"
        end
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
            when :datetime
              Time col_name
            end
          end
        end
      end

      def drop_table(table_name)
        @db.drop_table(table_name)
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

      def add_obj(obj, save_belongs_tos: true)
        # return if already in database
        return if obj.db_obj

        obj.added_to_db(@database,
                        db_obj: sequel_klass(obj).create(db_attrs(obj, save_belongs_tos: save_belongs_tos)),
                        rel_adapter: Obj::DatabaseAdapter::SqliteRelationship.new(obj, self))
        obj
      end

      def belongs_to_read(obj, rel)
        db_obj = obj.db_obj.send("sequel_#{rel.name}".to_sym)
        return nil unless db_obj
        wrap_obj(db_obj, obj.type_sym)
      end

      def sequel_klass(obj)
        @type_sym_to_sequel_class[obj.type_sym]
      end

      def db_attrs(obj, save_belongs_tos: true)
        belongs_to_rels = belongs_to_relationships(obj)
        belongs_to_keys = belongs_to_rels.map{ |_,rel| rel.foreign_key }
        attrs = obj.attrs.reject{ |k,_| belongs_to_keys.include?(k) || k == :id }
        attrs.merge(
          save_belongs_tos ?
            translated_foreign_key_attrs(obj, belongs_to_rels) :
            {}
        )
      end

      def translated_foreign_key_attrs(obj, belongs_to_rels)
        belongs_to_rels.map do |name, rel|
          rel_obj = obj.send(name)
          if rel_obj && !rel_obj.db_obj
            add_obj(rel_obj)
          end
          [rel.foreign_key, rel_obj&.db_obj&.id]
        end.to_h
      end

      def belongs_to_relationships(obj)
        klass = type_sym_to_class(obj.type_sym)
        klass.relationships.select do |_name, relationship|
          relationship.rel_type == :belongs_to
        end
      end

      def rem_obj(obj)
      end

      def update_obj(obj)
        belongs_to_relationships(obj).each do |name, rel|
          rel_obj = obj.send(name)
          if rel_obj
            rel_val = rel_obj.db_obj
          else
            rel_val = nil
          end
          obj.db_obj.send("sequel_#{name}=", rel_val)
        end
        obj.db_obj.update(db_attrs(obj))
      end

      def where_by(type_sym, finder_hash)
        klass = @type_sym_to_sequel_class[type_sym]
        db_objs = klass.where(finder_hash)
        db_objs.map { |db_obj| wrap_obj(db_obj, type_sym) }
      end

      def find_by(type_sym, finder_hash)
        where_by(type_sym, finder_hash).first
      end

      def connect
        # @db = Sequel.connect("sqlite://test-#{rand(100)}.sqlite")
        @db = Sequel.connect("sqlite://#{self.class.db_filename}")
      end

      def disconnect
        @db.disconnect
      end

      def unlink
        begin
          File.unlink(self.class.db_filename)
        rescue
          puts "couldn't unlink filename #{self.class.db_filename}"
        end
        @db = nil
      end

      def register_class(obj_class)
        sequel_class = create_sequel_class(obj_class)
        @type_sym_to_sequel_class[obj_class.get_type_sym] = sequel_class
        @sequel_class_to_type_sym[sequel_class.to_s] = obj_class.get_type_sym
      end

      def create_sequel_class(klass)
        str, class_name = sequel_class_str(klass)
        eval(str)
        r = eval(class_name)
        r
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
            if rel.through
              through = klass.relationships[rel.through]
              through_table = through.target_type_sym
              "many_to_many :sequel_#{rel.name}, " +
                "join_table: :sequel_#{through_table}, " +
                "left_key: :sequel_#{through.foreign_key}, " +
                "right_key: :sequel_#{rel.through_next}_id "
            else
              "one_to_many :sequel_#{rel.name}, key: :#{rel.foreign_key}"
            end
          end
        end

        class_def_str =
          "class " + class_name +
            " < Sequel::Model(:#{type_sym});" +
            rels.join(";") + ";end"
        puts "class def: #{class_def_str}"

        [class_def_str, class_name]
      end

      def type_sym_to_sequel_class(type_sym)
        @classes[type_sym]
      end

      def type_sym_to_class(type_sym)
        Obj.classes[type_sym]
      end

      def wrap_obj(sequel_obj, type_sym)
        obj = type_sym_to_class(type_sym).allocate
        attrs = sequel_obj.values.reject{|k,_| k == :id}
        obj.reset(type_sym, SecureRandom.hex, attrs, rel_adapter: Obj::DatabaseAdapter::SqliteRelationship.new(obj, self))
        obj.added_to_db(
          @database,
          db_obj: sequel_obj,
          rel_adapter: Obj::DatabaseAdapter::SqliteRelationship.new(obj, self))
        obj
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
