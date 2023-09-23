module Taggable
  def self.included(base)
    base.class_eval do
      has_many :taggings, :tagging, :taggable_id, as: :taggable, inverse_of: :taggable
    end
  end
end