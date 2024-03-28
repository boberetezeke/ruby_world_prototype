class Obj::Changes
  def initialize
    @changes = {}
  end

  def add(change)
    return if change.old_value == change.new_value

    last_change = @changes[change.sym]
    if last_change
      if last_change.old_value == change.new_value
        @changes.delete(change.sym)
      else
        @changes[change.sym] = Obj::Change.new(change.sym, last_change.old_value, change.new_value)
      end
    else
      @changes[change.sym] = change
    end
  end

  def for_sym(sym)
    @changes[sym]
  end

  def empty?
    @changes.empty?
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    @changes.to_a.all?{ |k, v| other.for_sym(k) == v}
  end
end