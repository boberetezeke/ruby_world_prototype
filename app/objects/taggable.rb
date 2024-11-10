module Taggable
  def self.included(base)
    base.class_eval do
      has_many :taggings, :tagging, :taggable_id, as: :taggable, inverse_of: :taggable
      has_many :tags, :tag, nil, through: :taggings,
               through_next: :tag, through_back: :taggable, through_type_sym: :tagging
    end
  end
end