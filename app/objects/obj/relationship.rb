class Relationship
  attr_reader :rel_type, :name, :foreign_key, :foreign_type
  attr_reader :target_type_sym, :inverse_of, :index, :polymorphic, :poly_classes
  attr_reader :through, :through_next, :through_back, :through_type_sym
  def initialize(rel_type, rel_name, foreign_key, target_type_sym,
                 inverse_of: nil,
                 classes: nil,
                 polymorphic: nil,
                 poly_classes: [],
                 as: nil,
                 through: nil, through_next: nil, through_back: nil, through_type_sym: nil)
    @rel_type = rel_type
    @name = rel_name
    @foreign_key = foreign_key
    @target_type_sym = target_type_sym
    @polymorphic = polymorphic
    @poly_classes = poly_classes
    @foreign_type = @foreign_key.to_s.gsub(/_id$/, '_type').to_sym if @polymorphic
    @inverse_of = as || inverse_of
    @inverse_type = as ? "#{as}_type".to_sym : nil
    @classes = classes
    @index = Index.new if @rel_type == :has_many
    @through = through
    @through_next = through_next
    @through_back = through_back
    @through_type_sym = through_type_sym
  end

  def reset_index
    @index&.reset
  end

  def new_through_obj(obj, source)
    through_obj = Obj.new_blank_obj(@through_type_sym)
    through_obj.send("#{@through_next}=", obj)
    through_obj.send("#{@through_back}=", source)
    through_obj
  end

  def inverse(obj)
    if @inverse_of
      target_type_sym = @polymorphic ? obj.send(@foreign_type) : @target_type_sym
      return @classes[target_type_sym].relationships[@inverse_of]
    end
    nil
  end
end
