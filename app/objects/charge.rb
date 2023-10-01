class Obj::Charge < Obj
  include Taggable

  belongs_to :vendor, :vendor_id, inverse_of: :charges
  belongs_to :credit_card, :credit_card_id, inverse_of: :charges

  def self.default_display
    {
      sym_sets: {
        default: [:id, :remote_id, :amount]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        remote_id: { width: 30, type: :string, title: 'Remote ID' },
        # TODO: should be decimal instead of float
        amount: { width: 15, type: :float, title: 'amount' },
      }
    }
  end

  def initialize(remote_id, amount)
    super(:charge, {remote_id: remote_id, amount: amount})
  end
end
