class Obj::BudgetTarget < Obj
  include Taggable

  def self.default_display
    {
      sym_sets: {
        default: [:month, :amount, :calc_amount]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        month: { width: 35, type: :integer, title: 'month', format: '%d' },
        amount: { width: 15, type: :float, title: 'amount', format: '%.2f' },
        week_1_amount: { width: 15, type: :float, title: 'week_1_amount', format: '%.2f' },
        week_2_amount: { width: 15, type: :float, title: 'week_2_amount', format: '%.2f' },
        week_3_amount: { width: 15, type: :float, title: 'week_3_amount', format: '%.2f' },
        week_4_amount: { width: 15, type: :float, title: 'week_4_amount', format: '%.2f' },
        calc_amount: { width: 15, type: :float, title: 'calc_amount', format: '%.2f' },
        week_1_calc_amount: { width: 15, type: :float, title: 'week_1_calc_amount', format: '%.2f' },
        week_2_calc_amount: { width: 15, type: :float, title: 'week_2_calc_amount', format: '%.2f' },
        week_3_calc_amount: { width: 15, type: :float, title: 'week_3_calc_amount', format: '%.2f' },
        week_4_calc_amount: { width: 15, type: :float, title: 'week_4_calc_amount', format: '%.2f' },
      }
    }
  end

  def initialize(month,
                 amount: nil,
                 week_1_amount: nil,
                 week_2_amount: nil,
                 week_3_amount: nil,
                 week_4_amount: nil,
                 calc_amount: nil,
                 week_1_calc_amount: nil,
                 week_2_calc_amount: nil,
                 week_3_calc_amount: nil,
                 week_4_calc_amount: nil)
    super(:budget_target, {
      month: month,
      amount: amount,
      week_1_amount: week_1_amount,
      week_2_amount: week_2_amount,
      week_3_amount: week_3_amount,
      week_4_amount: week_4_amount,
      calc_amount: calc_amount,
      week_1_calc_amount: week_1_calc_amount,
      week_2_calc_amount: week_2_calc_amount,
      week_3_calc_amount: week_3_calc_amount,
      week_4_calc_amount: week_4_calc_amount
    })
  end
end