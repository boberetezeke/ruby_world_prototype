class Relationship
  attr_reader :rel_type, :name, :foreign_key, :foreign_type
  attr_reader :target_type_sym, :inverse_of, :index, :polymorphic
  attr_reader :through, :through_next
  def initialize(rel_type, rel_name, foreign_key, target_type_sym,
                 inverse_of: nil,
                 classes: nil,
                 polymorphic: nil,
                 as: nil,
                 through: nil, through_next: nil)
    @rel_type = rel_type
    @name = rel_name
    @foreign_key = foreign_key
    @target_type_sym = target_type_sym
    @polymorphic = polymorphic
    @foreign_type = @foreign_key.to_s.gsub(/_id$/, '_type').to_sym if @polymorphic
    @inverse_of = as || inverse_of
    @inverse_type = as ? "#{as}_type".to_sym : nil
    @classes = classes
    @index = Index.new if @rel_type == :has_many
    @through = through
    @through_next = through_next
  end

  def reset_index
    @index&.reset
  end

  def inverse(obj)
    if @inverse_of
      target_type_sym = @polymorphic ? obj.send(@foreign_type) : @target_type_sym
      return @classes[target_type_sym].relationships[@inverse_of]
    end
    nil
  end
end
