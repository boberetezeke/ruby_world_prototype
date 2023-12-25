class Obj::CreditCard < Obj
  has_many :charges, :charge, :credit_card_id, inverse_of: :credit_card

  def self.default_display
    {
      sym_sets: {
        default: [:id, :last_four_digits]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        last_four_digits: { width: 5, type: :string, title: 'Last 4' },
      }
    }
  end

  def initialize(last_four_digits)
    super(:credit_card, {last_four_digits: last_four_digits})
  end
end
