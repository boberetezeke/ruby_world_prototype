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
