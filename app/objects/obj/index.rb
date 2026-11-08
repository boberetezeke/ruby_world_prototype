class Index
  def initialize
    reset
  end

  def reset
    @index = {}
  end

  def values
    @index.values
  end

  def add(k, v)
    return if k.nil?

    if @index.has_key?(k)
      @index[k].push(v) unless @index[k].include?(v)
    else
      @index[k] = [v]
    end
  end

  def remove(k, v)
    return if k.nil?

    @index[k]&.delete(v)
  end

  def update(old_k, new_k, v)
    remove(old_k, v)
    add(new_k, v)
  end

  def [](index)
    @index[index] || []
  end
end

class HasOneIndex
  def initialize
    @value = nil
  end

  def reset
    @value = nil
  end

  def values
    [@value]
  end

  def add(k, v)
    @value = v
  end

  def remove(k, v)
    @value = nil
  end

  def update(old_k, new_k, v)
    @value = v
  end

  def [](index)
    @value || []
  end
end
