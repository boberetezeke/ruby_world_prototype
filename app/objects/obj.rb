require 'date'
require 'securerandom'

path = File.dirname(__FILE__)

load "#{path}/obj/index.rb"
load "#{path}/obj/has_many_array.rb"
load "#{path}/obj/relationship.rb"

class Obj
  attr_reader :id, :type_sym, :attrs, :rel_attrs
  def initialize(type_sym, attrs, rel_attrs: {})
    reset(type_sym, SecureRandom.hex, attrs, rel_attrs: rel_attrs)
  end

  def reset(type_sym, id, attrs, rel_attrs: nil)
    @type_sym = type_sym
    @id = id
    @attrs = attrs
    @tags = []
    @rel_attrs = rel_attrs || default_belongs_to_attrs

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
    other.id == @id
  end

  def hash
    @id
  end

  def self.belongs_to(rel_name, foreign_key, inverse_of: nil)
    @relationships ||= {}
    @relationships[rel_name] = Relationship.new(
      :belongs_to,
      rel_name,
      foreign_key,
      rel_name,
      inverse_of: inverse_of,
      classes: classes
    )

  end

  def self.has_many(rel_name, target_type_sym, foreign_key, inverse_of: nil)
    @relationships ||= {}
    @relationships[rel_name] =
      Relationship.new(
        :has_many,
        rel_name,
        foreign_key,
        target_type_sym,
        classes: classes,
        inverse_of: inverse_of
      )
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

  def update_indexes(obj)
    relationships.each do |_, rel|
      if rel.rel_type == :belongs_to && rel.inverse_of
        belongs_to_obj = obj.send(rel.name)
        rel.inverse.index.add(belongs_to_obj.id, obj) if belongs_to_obj
      end
    end
  end

  def inspect
    @attrs.merge(@rel_attrs)
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

  def belongs_to_assign(rel, rhs)
    old_val = @rel_attrs[rel.foreign_key]
    new_val = rhs&.id
    @rel_attrs[rel.foreign_key] = new_val
    rel.inverse.index.update(old_val, new_val, self)
  end

  def has_many_assign(rel, rhs)
    raise 'has_many relationships can only accept array values' unless rhs.is_a?(Array)
    rel.index[self.id].each do |obj|
      obj.send("#{rel.rel_name}=", nil)
    end
    rhs.each do |obj|
      obj.send("#{rel.inverse.name}=", self)
    end
  end

  def attr_assign(sym, rhs)
    if attrs_and_defaults.keys.include?(sym)
      return @attrs[sym] = rhs
    elsif relationships.include?(sym)
      rel = relationships[sym]
      if rel.rel_type == :belongs_to
        belongs_to_assign(rel, rhs)
        return true
      elsif rel.rel_type == :has_many
        has_many_assign(rel, rhs)
        return true
      end
    end
    return false
  end

  def relationship_read(sym)
    rel = relationships[sym]
    if rel.rel_type == :belongs_to
      id = @rel_attrs[rel.foreign_key]
      ret_value = id.nil? ? nil : self.class.objects[id]
      return [true, ret_value]
    elsif rel.rel_type == :has_many
      return [true, HasManyArray.new(self, rel, rel.index[self.id])]
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

  def add_tag(tag)
    @tags.push(tag) unless @tags.include(tag)
  end
end
