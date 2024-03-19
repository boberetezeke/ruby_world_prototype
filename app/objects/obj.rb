require 'date'
require 'securerandom'

path = File.dirname(__FILE__)

load "#{path}/obj/index.rb"
load "#{path}/obj/has_many_array.rb"
load "#{path}/obj/relationship.rb"
load "#{path}/database_adapter/in_memory_relationship.rb"

class Obj
  attr_reader :id, :type_sym, :attrs, :changes, :db

  def initialize(type_sym, attrs, track_changes: true)
    reset(type_sym, SecureRandom.hex, attrs, track_changes: track_changes)
    @rel_adapter = Obj::DatabaseAdapter::InMemoryRelationship.new
  end

  def added_to_db(db)
    @db = db
    # pick database relationship handler here?
    # @rel_adapter = Obj::DatabaseAdapter::InMemoryRelationship.new
  end

  def reset(type_sym, id, attrs, track_changes: true)
    @type_sym = type_sym
    @id = id
    @attrs = default_belongs_to_attrs.merge(attrs)
    @changes = Obj::Changes.new
    if track_changes
      @attrs.each do |attr, value|
        @changes.add(Obj::Change.new(attr, nil, value))
      end
    end

    self.class.objects[@id] = self
    self.class.classes[type_sym] = self.class
    update_indexes(self)
    self
  end

  def dup
    d = self.class.allocate
    d.reset(@type_sym, SecureRandom.hex, @attrs)
  end

  def default_belongs_to_attrs
    return @default_rel_attrs if @default_rel_attrs
    @default_rel_attrs = self.class.relationships.select do |_, rel|
      rel.rel_type == :belongs_to
    end.map do |_, rel|
      [rel.foreign_key, nil]
    end.to_h
  end

  def self.defaults
    nil
  end

  def defaults
    self.class.defaults || {}
  end

  def attrs_and_defaults
    defaults.merge(@attrs)
  end

  def ==(other)
    if (other.db.nil? && !@db.nil?) || (!other.db.nil? && @db.nil?)
      return false
    elsif other.db && @db
      other.id == @id
    else
      other.attrs == @attrs
    end
  end

  def hash
    @id
  end

  def self.belongs_to(rel_name, foreign_key, inverse_of: nil, polymorphic: nil)
    @relationships ||= {}
    relationship = Relationship.new(
      :belongs_to,
      rel_name,
      foreign_key,
      rel_name,
      inverse_of: inverse_of,
      polymorphic: polymorphic,
      classes: classes
    )
    @relationships[rel_name] = relationship
    # @relationships[relationship.foreign_key] = relationship
    # @relationships[relationship.foreign_type] = relationship if relationship.foreign_type
  end

  def self.has_many(rel_name, target_type_sym, foreign_key,
                    inverse_of: nil,
                    polymorphic: false,
                    as: nil,
                    through: nil,
                    through_next: nil)
    @relationships ||= {}
    relationship =
      Relationship.new(
        :has_many,
        rel_name,
        foreign_key,
        target_type_sym,
        classes: classes,
        inverse_of: inverse_of,
        polymorphic: polymorphic,
        as: as,
        through: through,
        through_next: through_next
      )
    @relationships[rel_name] = relationship
  end

  def self.relationships
    @relationships ||= {}
    @relationships
  end

  def self.objects
    @@objects ||= {}
    @@objects
  end

  def self.classes
    @@classes ||= {}
    @@classes
  end

  def self.indexes
    @indexes
  end

  def self.new_from_db(type_sym, attrs)
    obj = @@classes[type_sym].allocate
    obj.reset(type_sym, SecureRandom.hex, attrs)
    obj
  end

  def update_indexes(obj)
    relationships.each do |_, rel|
      if rel.rel_type == :belongs_to && rel.inverse_of
        belongs_to_obj = obj.send(rel.name)
        rel.inverse(obj).index.add(belongs_to_obj.id, obj) if belongs_to_obj
      end
    end
  end

  def inspect
    @attrs
  end

  def relationships
    self.class.relationships
  end

  def update(obj)
    @attrs = obj.attrs
  end

  def remove_keys(*keys)
    keys.flatten.each do |key|
      @attrs.delete(key)
    end
  end

  def simple_assign(sym, rhs)
    @changes.add(Obj::Change.new(sym, @attrs[sym], rhs))
    @attrs[sym] = rhs
    true
  end

  def attr_assign(sym, rhs)
    if attrs_and_defaults.keys.include?(sym)
      return simple_assign(sym, rhs)
    elsif relationships.include?(sym)
      rel = relationships[sym]
      if rel.rel_type == :belongs_to
        @rel_adapter.belongs_to_assign(rel, rhs)
        return true
      elsif rel.rel_type == :has_many
        @rel_adapter.has_many_assign(rel, rhs)
        return true
      end
    end
    return false
  end

  def relationship_read(sym)
    rel = relationships[sym]
    if rel.rel_type == :belongs_to
      return [true, @rel_adapter.belongs_to_relationship_read(rel)]
    elsif rel.rel_type == :has_many
      if rel.through
        return [true, @rel_adapter.has_many_through_read(rel)]
      else
        return [true, @rel_adapter.has_many_read(rel)]
      end
    end
    return [false, nil]
  end

  def attr_read(sym)
    if attrs_and_defaults.keys.include?(sym)
      return [true, @attrs[sym]]
    elsif relationships.include?(sym)
      complete, ret_value = relationship_read(sym)
      return [complete, ret_value] if complete
    end
    return [false, nil]
  end

  def save
    @db.update_obj(self)
  end

  def method_missing(sym, *args)
    m = /^(.*)=/.match(sym.to_s)
    if m && args.size == 1
      sym = m[1].to_sym
      rhs = args.first
      complete = attr_assign(sym, rhs)
      return rhs if complete
    elsif args.size == 0
      complete, ret_value = attr_read(sym)
      return ret_value if complete
    end

    super
  end
end
