class Obj::Collection
  def initialize(obj_type)
    @collection = {}
    @obj_type = obj_type
  end

  def objs(db)
    @collection.values.map{|db_id| db.objs[@obj_type][db_id]}
  end

  def add(obj)
    @collection[obj.id] = obj.id unless @collection.has_key?(obj.id)
  end

  def remove(obj)
    @collection.delete(obj.id)
  end
end