class Obj::DatabaseAdapter::InMemoryRelationship
  def belongs_to_read(rel)
    id = @attrs[rel.foreign_key]
    id.nil? ? nil : self.class.objects[id]
  end

  def belongs_to_assign(rel, rhs)
    old_val = @attrs[rel.foreign_key]
    new_val = rhs&.id
    foreign_key = rel.foreign_key
    @changes.add(Obj::Change.new(foreign_key, @attrs[foreign_key], new_val))
    @attrs[rel.foreign_key] = new_val
    @attrs[rel.foreign_type] = rhs.type_sym if rel.polymorphic && !rhs.nil?
    rel.inverse(self).index.update(old_val, new_val, self)
    @attrs[rel.foreign_type] = nil if rel.polymorphic && rhs.nil?
  end

  def has_many_read(rel)
    HasManyArray.new(self, rel, rel.index[self.id])
  end

  def has_many_through_read(rel)
    complete, has_many_array = relationship_read(rel.through)
    return [false, nil] unless complete
    objs = has_many_array.to_a.map do |obj|
      val_or_vals = obj.send(rel.through_next)
      if val_or_vals.is_a?(HasManyArray)
        val_or_vals.to_a
      else
        [val_or_vals]
      end
    end.flatten
  end

  def has_many_assign(rel, rhs)
    raise 'has_many relationships can only accept array values' unless rhs.is_a?(Array)
    rel.index[self.id].each do |obj|
      obj.send("#{rel.rel_name}=", nil)
    end
    rhs.each do |obj|
      obj.send("#{rel.inverse(self).name}=", self)
    end
  end
end