require 'date'
require 'securerandom'

class Obj
  attr_reader :id, :type_sym, :attrs, :rel_attrs
  def initialize(type_sym, attrs)
    @tags = []
    @type_sym = type_sym
    @attrs = attrs
    @rel_attrs = {}
    @id =  SecureRandom.hex

    self.class.objects[@id] = self
  end

  def self.belongs_to(relationship, foreign_key)
    @relationships ||= {}
    @relationships[relationship] = {
      type: :belongs_to,
      foreign_key: foreign_key,
      name: relationship
    }
  end

  def self.has_many(relationship, name, foreign_key)
    @relationships ||= {}
    @relationships[relationship] = {
      type: :has_many,
      foreign_key: foreign_key,
      name: name
    }
  end

  def self.relationships
    @relationships || {}
  end

  def self.objects
    @objects || {}
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
        if rel[:type] == :belongs_to
          return @rel_attrs[sym] = rel[:foreign_key]
        elsif rel[:type] == :has_many
          return self.class.objects[rel[:name]].select{|obj| obj.send(rel[:foreign_key] == self.id)}
        end
      end
    elsif args.size == 0
      if @attrs.keys.include?(sym)
        return @attrs[sym]
      elsif relationships.include?(sym)
        rel = relationships[sym]
        if rel[:type] == :belongs_to
          return self.class.objects[rel[:name]][@rel_attrs[sym]]
        elsif rel[:type] == :has_many
          return self.class.objects[rel[:name]].select{|obj| obj.send(rel[:foreign_key] == self.id)}
        end
      end
    end

    super
  end

  def add_tag(tag)
    @tags.push(tag) unless @tags.include(tag)
  end
end
