class Obj::DatabaseAdapter::SqliteRelationship
  attr_accessor :in_mem_adapter
  def initialize(obj, sequel_adapter)
    @obj = obj
    @sequel_adapter = sequel_adapter
  end

  def belongs_to_read(rel)
    @sequel_adapter.belongs_to_read(@obj, rel)
  end

  def belongs_to_assign(rel, rhs)
    @in_mem_adapter.belongs_to_assign(rel, rhs)
  end

  def has_many_read(rel)
    sequel_objs = @obj.db_obj.send("sequel_#{rel.name}")
    sequel_objs.map{ |sequel_obj| @sequel_adapter.wrap_obj(sequel_obj, @obj.type_sym) }
  end

  def has_many_through_read(rel)
    # complete, has_many_array = relationship_read(rel.through)
    # return [false, nil] unless complete
    # objs = has_many_array.to_a.map do |obj|
    #   val_or_vals = obj.send(rel.through_next)
    #   if val_or_vals.is_a?(HasManyArray)
    #     val_or_vals.to_a
    #   else
    #     [val_or_vals]
    #   end
    # end.flatten
  end

  def has_many_assign(rel, rhs)
    # raise 'has_many relationships can only accept array values' unless rhs.is_a?(Array)
    # rel.index[@obj.id].each do |obj|
    #   obj.send("#{rel.rel_name}=", nil)
    # end
    # rhs.each do |obj|
    #   obj.send("#{rel.inverse(@obj).name}=", @obj)
    # end
  end
end
