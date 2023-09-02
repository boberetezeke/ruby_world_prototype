class Relationship
  attr_reader :rel_type, :name, :foreign_key, :target_type_sym, :inverse_of, :index
  def initialize(rel_type, rel_name, foreign_key, target_type_sym, inverse_of: nil, classes: nil)
    @rel_type = rel_type
    @name = rel_name
    @foreign_key = foreign_key
    @target_type_sym = target_type_sym
    @inverse_of = inverse_of
    @classes = classes
    @index = Index.new if @rel_type == :has_many
  end

  def reset_index
    @index&.reset
  end

  def inverse
    return @classes[@target_type_sym].relationships[@inverse_of] if @inverse_of
    nil
  end
end
