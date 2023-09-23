class Obj::Tagging < Obj
  belongs_to :tag, :tag_id, inverse_of: :taggings
  belongs_to :taggable, :taggable_id, polymorphic: true, inverse_of: :taggings

  def initialize
    super(:tagging, {})
  end
end