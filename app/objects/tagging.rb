class Tagging < Obj
  belongs_to :tag, :tag_id, inverse_of: :taggings
  belongs_to :obj, :obj_id, inverse_of: :objects

  def initialize
    super(:tagging, {})
  end
end