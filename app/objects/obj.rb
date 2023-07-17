require 'date'
require 'securerandom'

class Index
  def initialize
    reset
  end

  def reset
    @index = {}
  end

  def add(k, v)
    if @index.has_key?(k)
      @index[k].push(v)
    else
      @index[k] = [v]
    end
  end

  def remove(k, v)
    return if k.nil?
    @index[k].delete(v)
  end

  def update(old_k, new_k, v)
    remove(old_k, v)
    add(new_k, v)
  end

  def [](index)
    @index[index] || []
  end
end

class Relationship
  attr_reader :rel_type, :name, :foreign_key, :target_type_sym, :inverse_of, :index
  def initialize(rel_type, rel_name, foreign_key, target_type_sym, inverse_of: nil, classes: nil)
    @rel_type = rel_type
    @name = rel_name
    @foreign_key = foreign_key
    @target_type_sym = target_type_sym
    @inverse_of = inverse_of
    @classes = classes
    @index = Index.new if @rel_type == :has_many
  end

  def reset_index
    @index&.reset
  end

  def inverse
    return @classes[@target_type_sym].relationships[@inverse_of] if @inverse_of
    nil
  end
end

class HasManyArray
  attr_reader :array
  def initialize(obj, relationship, array)
    @obj = obj
    @relationship = relationship
    @array = array
  end

  def push(val)
    val.send("#{@relationship.inverse.name}=", @obj)
    @obj.send(@relationship.name)
  end

  def <<(val)
    push(val)
  end

  def delete(val)
    val.send("#{@relationship.inverse.name}=", nil)
    @obj.send(@relationship.name)
  end

  def to_a
    @array
  end

  def ==(other)
    if other.is_a?(Array)
      @array == other
    elsif other.is_a?(self.class)
      @array == other.array
    else
      false
    end
  end

  def method_missing(sym, *args, **hargs, &block)
    @array.send(sym, *args, **hargs, &block)
  end
end

class Obj
  attr_reader :id, :type_sym, :attrs, :rel_attrs
  def initialize(type_sym, attrs)
    reset(type_sym, SecureRandom.hex, attrs)
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
    d.reset(@type_sym, @id, @attrs)
  end

  def default_belongs_to_attrs
    return @default_rel_attrs if @default_rel_attrs
    @default_rel_attrs = self.class.relationships.select do |_, rel|
      rel.rel_type == :belongs_to
    end.map do |_, rel|
      [rel.foreign_key, nil]
    end.to_h
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

  def method_missing(sym, *args)
    m = /^(.*)=/.match(sym.to_s)
    if m && args.size == 1
      sym = m[1].to_sym
      rhs = args.first
      if @attrs.keys.include?(sym)
        return @attrs[sym] = rhs
      elsif relationships.include?(sym)
        rel = relationships[sym]
        if rel.rel_type == :belongs_to
          old_val = @rel_attrs[rel.foreign_key]
          new_val = rhs&.id
          @rel_attrs[rel.foreign_key] = new_val
          rel.inverse.index.update(old_val, new_val, self)
          return
        elsif rel.rel_type == :has_many
          raise 'has_many relationships can only accept array values' unless rhs.is_a?(Array)
          rel.index[self.id].each do |obj|
            obj.send("#{rel.rel_name}=", nil)
          end
          rhs.each do |obj|
            obj.send("#{rel.inverse.name}=", self)
          end
          return
        end
      end
    elsif args.size == 0
      if @attrs.keys.include?(sym)
        return @attrs[sym]
      elsif relationships.include?(sym)
        rel = relationships[sym]
        if rel.rel_type == :belongs_to
          id = @rel_attrs[rel.foreign_key]
          return id.nil? ? nil : self.class.objects[id]
        elsif rel.rel_type == :has_many
          return HasManyArray.new(self, rel, rel.index[self.id])
        end
      end
    end

    super
  end

  def add_tag(tag)
    @tags.push(tag) unless @tags.include(tag)
  end
end
