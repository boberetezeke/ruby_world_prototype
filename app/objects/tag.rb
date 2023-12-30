class Obj::Tag < Obj
  has_many :taggings, :tagging, :tag_id, inverse_of: :tag
  has_many :objs, nil, nil, through: :taggings, through_next: :taggable

  def self.tags_match?(tags_1, tags_2)
    Set.new(tags_1.map(&:name)) == Set.new(tags_2.map(&:name))
  end

  def initialize(name)
    super(:tag, {name: name})
  end

  def ==(other)
    return false unless other.is_a?(Tag)
    self.name == other.name
  end
end
