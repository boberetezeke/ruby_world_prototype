class Obj::Vendor < Obj
  type_sym :vendor

  has_many :charges, :charge, :vendor_id, inverse_of: :vendor

  def self.default_display
    {
      sym_sets: {
        default: [:id, :name]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        name: { width: 20, type: :string, title: 'team name' },
      }
    }
  end

  def initialize(name, address)
    super(:vendor, {name: name, address: address})
  end
end

