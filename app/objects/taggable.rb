module Taggable
  def self.included(base)
    base.class_eval do
      has_many :taggings, :tagging, :taggable_id, as: :taggable, inverse_of: :taggable
      has_many :tags, nil, nil, through: :taggings, through_next: :tag
    end
  end
end