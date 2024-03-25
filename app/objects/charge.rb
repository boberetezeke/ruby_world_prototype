class Obj::Charge < Obj
  include Taggable

  type_sym :charge
  belongs_to :vendor, :vendor_id, inverse_of: :charges
  belongs_to :credit_card, :credit_card_id, inverse_of: :charges

  def self.default_display
    {
      sym_sets: {
        default: [:posted_date, :amount, :description, :tags]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        remote_id: { width: 30, type: :string, title: 'Remote ID' },
        # TODO: should be decimal instead of float
        amount: { width: 15, type: :float, title: 'amount', format: '%.2f' },
        posted_date: { width: 15, type: :date, title: 'date' },
        description: { width: 40, type: :string, title: 'description' },
        tags: { width: 25, type: :tags, title: 'tags' },
      }
    }
  end

  def self.total_obj(charges)
    Charge.new(nil, charges.map(&:amount).sum, nil)
  end

  def initialize(remote_id, amount, posted_date, description: nil)
    super(:charge, {
      posted_date: posted_date,
      remote_id: remote_id,
      amount: amount,
      description: description
    })
  end
end
