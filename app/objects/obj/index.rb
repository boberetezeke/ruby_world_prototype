class Index
  def initialize
    reset
  end

  def reset
    @index = {}
  end

  def add(k, v)
    return if k.nil?

    if @index.has_key?(k)
      @index[k].push(v)
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
