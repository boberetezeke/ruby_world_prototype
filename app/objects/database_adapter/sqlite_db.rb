require 'sequel'

class Obj
  module DatabaseAdapter
    class PolymorphicRelation
      def initialize(database, join_rel, has_many_relation)
        @database = database
        @join_rel = join_rel
        @has_many_relation = has_many_relation
      end

      def to_ary
        to_a
      end

      def to_a
        @has_many_relation.to_a.map do |join_table_row|
          o = join_table_row.send(@join_rel.through_next)
          o
        end
      end
    end

    class SqliteDb
      class Relation
        attr_reader :type_sym
        def initialize(database, type_sym)
          @database = database
          @type_sym = type_sym
        end

        def size
          values.size
        end

        def values
          all
        end

        def all
          # TODO: need to find the sequel class for the type sym and do an all for that
          klass = @database.type_sym_to_sequel_class(@type_sym)
          klass.all.map do |obj|
            @database.wrap_obj(obj, @type_sym)
            # Obj.new_from_db(@table_name, attrs)
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
          next if database.database_adapter.db[:schema_migrations].where(name: migration.to_s).count > 0

          migration.up(database)
          database.database_adapter.db.execute("INSERT INTO schema_migrations (name) VALUES ('#{migration}')")
        end
      end

      def self.rollback(all_migrations, database)
        all_migrations.each do |migration|
          migration.down(database)
          database.database_adapter.db.execute("DELETE FROM schema_migrations where name='#{migration}'")
        end
      end

      def self.db_filename
        'test.sqlite'
      end

      def self.load_or_reload(database, _database_adapter, filename)
        new(database, filename)
      end

      attr_reader :db

      def initialize(database, filename)
        @database = database
        @filename = filename
        @type_sym_to_sequel_class = {}
        @sequel_class_to_type_sym = {}
        @class_to_type_sym = {}
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
        @db[relation.type_sym].all
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
        if rel.polymorphic
          # need to use the appropriate belongs_to relationship based on obj.db_obj.taggable_type
          # Obj::Charge ==> obj.db_obj.charge
          target_type_sym = eval(obj.db_obj.taggable_type).get_type_sym
          db_obj = obj.db_obj.send("sequel_#{target_type_sym}".to_sym)
        else
          db_obj = obj.db_obj.send("sequel_#{rel.name}".to_sym)
          target_type_sym = rel.target_type_sym
        end
        return nil unless db_obj
        wrap_obj(db_obj, target_type_sym)
      end

      def has_many_read(obj, rel)
        if rel.rel_type == :has_many && rel.through_next
          PolymorphicRelation.new(self, rel, obj.send(rel.through))
        else
          sequel_objs = obj.db_obj.send("sequel_#{rel.name}")
          sequel_objs.map{ |sequel_obj| wrap_obj(sequel_obj, rel.target_type_sym) }
        end
      end

      def sequel_klass(obj)
        sequel_klass_from_type_sym(obj.type_sym)
      end

      def sequel_klass_from_type_sym(type_sym)
        @type_sym_to_sequel_class[type_sym]
      end

      def db_attrs(obj, save_belongs_tos: true)
        belongs_to_rels = belongs_to_relationships(obj)
        belongs_to_keys = belongs_to_rels.map{ |_,rel| rel.foreign_key }
        belongs_to_types = belongs_to_rels.map{ |_,rel| rel.foreign_type }.compact
        attrs = obj.attrs.reject do |k,_|
          belongs_to_keys.include?(k) ||
          belongs_to_types.include?(k) ||
          k == :id
        end
        attrs.merge(
          save_belongs_tos ?
            translated_foreign_key_attrs(obj, belongs_to_rels) :
            {}
        )
      end

      def translated_foreign_key_attrs(obj, belongs_to_rels)
        k_and_vs = []
        belongs_to_rels.each do |name, rel|
          rel_obj = obj.send(name)
          if rel_obj && !rel_obj.db_obj
            add_obj(rel_obj)
          end
          k_and_vs.push([rel.foreign_key, rel_obj&.db_obj&.id])
          if rel_obj && rel.foreign_type
            k_and_vs.push([rel.foreign_type, rel_obj&.class.to_s])
          end
        end

        k_and_vs.to_h
      end

      def belongs_to_relationships(obj)
        klass = type_sym_to_class(obj.type_sym)
        klass.relationships.select do |_name, relationship|
          relationship.rel_type == :belongs_to
        end
      end

      def rem_obj(obj)
        obj.db_obj.destroy
      end

      def update_obj(obj)
        belongs_to_relationships(obj).each do |name, rel|
          rel_obj = obj.belongs_to_read(rel, use_cache: false)
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
        db_objs = klass.where(convert_finder_hash(type_sym, finder_hash))
        db_objs.map { |db_obj| wrap_obj(db_obj, type_sym) }
      end

      def find_by(type_sym, finder_hash)
        where_by(type_sym, finder_hash).first
      end

      def convert_finder_hash(type_sym, finder_hash)
        klass = type_sym_to_class(type_sym)
        fh = Hash[
          finder_hash.map do |k,v|
            if klass.relationships[k]
              [klass.relationships[k].foreign_key, v.db_obj.id]
            elsif v.is_a?(Symbol)
              [k, type_sym_to_class(v).to_s]
            else
              [k, v]
            end
          end
        ]
        fh
      end

      def connect
        # @db = Sequel.connect("sqlite://test-#{rand(100)}.sqlite")
        @db = Sequel.connect("sqlite://#{@filename}")
        create_migration_table
      end

      def create_migration_table
        return if @db.table_exists?(:schema_migrations)

        create_table( :schema_migrations, { name: :string })
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
        @class_to_type_sym[obj_class.to_s] = obj_class.get_type_sym
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
            if rel.polymorphic
              rel.poly_classes.map do |poly_class|
                "many_to_one :sequel_#{poly_class}, key: :#{rel.foreign_key}"
              end
            else
              "many_to_one :sequel_#{rel.name}, key: :#{rel.foreign_key}"
            end
          when :has_many
            if rel.through
              through = klass.relationships[rel.through]
              through_table = through.target_type_sym
              "many_to_many :sequel_#{rel.name}, " +
                "join_table: :#{through_table}, " +
                "left_key: :#{through.foreign_key}, " +
                "right_key: :#{rel.through_next}_id "
            else
              "one_to_many :sequel_#{rel.name}, key: :#{rel.foreign_key}"
            end
          end
        end.flatten

        class_undef_str = "#{self.class}.send(:remove_const, '#{class_name}') rescue nil;"
        class_def_str =
          "class " + class_name +
            " < Sequel::Model(@db[:#{type_sym}]);" +
            rels.join(";") + ";end"
        # puts "class def: #{class_def_str}"

        [class_undef_str + class_def_str, class_name]
      end

      def type_sym_to_sequel_class(type_sym)
        @type_sym_to_sequel_class[type_sym]
      end

      def type_sym_to_class(type_sym)
        Obj.classes[type_sym]
      end

      def wrap_obj(sequel_obj, type_sym)
        klass = type_sym_to_class(type_sym)
        obj = klass.allocate
        attrs = sequel_obj.values.reject{|k,_| k == :id}
        translate_polymorphic_values(klass, attrs)
        obj.reset(type_sym, SecureRandom.hex, attrs, rel_adapter: Obj::DatabaseAdapter::SqliteRelationship.new(obj, self))
        obj.added_to_db(
          @database,
          db_obj: sequel_obj,
          rel_adapter: Obj::DatabaseAdapter::SqliteRelationship.new(obj, self))
        obj
      end

      # translate class names like Obj::Charge to type sym, looke :charge
      def translate_polymorphic_values(klass, attrs)
        klass.relationships.each do |k, rel|
          if rel.polymorphic
            foreign_type_value = attrs[rel.foreign_type]
            attrs[rel.foreign_type] = @class_to_type_sym[foreign_type_value]
          end
        end
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

      def polymorphic_relation_str(objable, reciprocal)
        <<-EOT
          many_to_one :attachable, reciprocal: :assets, reciprocal_type: :one_to_many,
            setter: (lambda do |attachable|
              self[:attachable_id] = (attachable.pk if attachable)
              self[:attachable_type] = (attachable.class.name if attachable)
            end),
            dataset: (proc do
              klass = attachable_type.constantize
              klass.where(klass.primary_key=>attachable_id)
            end),
            eager_loader: (lambda do |eo|
              id_map = {}
              eo[:rows].each do |asset|
                asset.associations[:attachable] = nil 
                ((id_map[asset.attachable_type] ||= {})[asset.attachable_id] ||= []) << asset
              end
              id_map.each do |klass_name, id_map|
                klass = klass_name.constantize
                klass.where(klass.primary_key=>id_map.keys).all do |attach|
                  id_map[attach.pk].each do |asset|
                    asset.associations[:attachable] = attach
                  end
                end
              end
            end)
        EOT
      end
    end
  end
end
