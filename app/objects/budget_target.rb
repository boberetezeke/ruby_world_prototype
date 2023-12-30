class Obj::BudgetTarget < Obj
  include Taggable

  def initialize(month,
                 amount: nil,
                 calc_amount: nil,
                 week_1_calc_amount: nil,
                 week_2_calc_amount: nil,
                 week_3_calc_amount: nil,
                 week_4_calc_amount: nil)
    super(:budget_target, {
      month: month,
      amount: amount,
      calc_amount: calc_amount,
      week_1_amount: week_1_calc_amount,
      week_2_amount: week_2_calc_amount,
      week_3_amount: week_3_calc_amount,
      week_4_amount: week_4_calc_amount
    })
  end
end