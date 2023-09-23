class Obj::Tag < Obj
  has_many :taggings, :tagging, :tag_id, inverse_of: :tag
  def initialize(name)
    super(:tag, {name: name})
  end

  def ==(other)
    return false unless other.is_a?(Tag)
    self.name == other.name
  end
end
