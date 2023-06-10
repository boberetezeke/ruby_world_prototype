class Obj::Database
  attr_reader :objs, :tags

  def initialize
    @objs = {}
    @tags = {}
  end

  def serialize
    {
      version: 1,
      objs: @objs,
      tags: @tags
    }
  end

  def deserialize(yml)
    @objs = yml[:objs]
    @tags = yml[:tags]
  end

  def write
    File.open("db.yml", "w") {|f| f.write(serialize.to_yaml) }
  end

  def self.read
    database = self.new
    return database unless File.exist?("db.yml")

    yml = File.open("db.yml") { |f| YAML.load(f) }
    database.deserialize(yml)
    database
  end

  def add_obj(obj)
    objs_of_type = @objs[obj.type_sym] || {}
    @objs[obj.type_sym] = objs_of_type if @objs[obj.type_sym].nil?

    objs_of_type[obj.id] = obj
    obj
  end

  def find_by(type_sym, finder_hash)
    objs_of_type = @objs[type_sym] || {}
    objs_of_type.values.select do |obj|
      value_hash = finder_hash.keys.map{|key| [key, obj.send(key)]}.to_h
      value_hash == finder_hash
    end.first
  end

  def method_missing(sym, *args)
    if sym.to_s =~ /(.*)s/
      sym = $1.to_sym
    else
      return nil
    end

    if @objs.keys.include?(sym)
      @objs[sym].values
    else
      nil
    end
  end
end
