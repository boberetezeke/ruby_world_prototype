class Obj::DatabaseAdapter::InMemoryRelationship
  def initialize(obj)
    @obj = obj
  end

  def belongs_to_read(rel, use_cache: false)
    id = @obj.attrs[rel.foreign_key]
    id.nil? ? nil : @obj.class.objects[id]
  end

  def belongs_to_assign(rel, rhs)
    old_val = @obj.attrs[rel.foreign_key]
    new_val = rhs&.id
    foreign_key = rel.foreign_key
    @obj.changes.add(Obj::Change.new(foreign_key, @obj.attrs[foreign_key], new_val))
    @obj.attrs[rel.foreign_key] = new_val
    @obj.attrs[rel.foreign_type] = rhs.type_sym if rel.polymorphic && !rhs.nil?
    rel.inverse(@obj).index.update(old_val, new_val, @obj)
    @obj.attrs[rel.foreign_type] = nil if rel.polymorphic && rhs.nil?
  end

  def has_many_read(rel)
    if rel.through
      has_many_through_read(rel)
    else
      HasManyArray.new(@obj, rel, rel.index[@obj.id])
    end
  end

  def has_many_through_read(rel)
    # TODO: this doesn't work well with caching
    complete, has_many_array = @obj.relationship_read(rel.through, rel_adapter: self)
    return [false, nil] unless complete
    has_many_array.to_a.map do |obj|
      val_or_vals = obj.send(rel.through_next)
      if val_or_vals.is_a?(HasManyArray)
        val_or_vals.to_a
      else
        [val_or_vals]
      end
    end.flatten
  end

  def has_many_assign(rel, rhs)
    raise 'has_many relationships can only accept array values' unless rhs.respond_to?(:to_ary)
    rhs = rhs.to_a
    # re-assign index to contain rhs values
    # rel.index[@obj.id].each do |obj|
    #   obj.send("#{rel.name}=", nil)
    # end

    if rel.through
      through_type_sym = @obj.relationships[rel.through].target_type_sym
      foreign_key =  Obj.classes[through_type_sym].relationships[rel.through_next].foreign_key
      current_objs = @obj.relationships[rel.through].index[@obj.id]

      # convert both the rhs to ids and the join objects to ids and compare them
      rhs_id_hash = Hash[rhs.map{|rh| [rh.id, rh]}]
      current_objs_ids = current_objs.map{|join_obj| join_obj.send(foreign_key)}
      new_ids = rhs_id_hash.keys - current_objs_ids
      new_ids.each do |id|
        rel.new_through_obj(rhs_id_hash[id], @obj)
      end
    else
      # nil out currently assigned foreign keys
      has_many_read(rel).each do |obj|
        obj.send("#{rel.inverse(obj).name}=", nil)
      end

      # set new values
      rhs.to_a.each do |obj|
        obj.send("#{rel.inverse(@obj).name}=", @obj)
      end
    end
  end

  def update_indexes(relationships)
    relationships.each do |_, rel|
      if rel.rel_type == :belongs_to && rel.inverse_of
        belongs_to_obj = @obj.send(rel.name)
        rel.inverse(@obj).index.add(belongs_to_obj.id, @obj) if belongs_to_obj
      end
    end
  end
end