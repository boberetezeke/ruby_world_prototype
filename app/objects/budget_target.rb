class Obj::BudgetTarget < Obj
  include Taggable

  def initialize(month, amount: nil)
    super(:budget_target, {month: month, amount: amount})
  end
end