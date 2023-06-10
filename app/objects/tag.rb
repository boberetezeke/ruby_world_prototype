class Obj::Tag
  attr :name
  def initialize(name)
    @name = name
  end

  def ==(other)
    return false unless other.is_a?(Tag)
    self.name == other.name
  end
end
