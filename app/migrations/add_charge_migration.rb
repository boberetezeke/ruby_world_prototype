class Obj::AddChargeMigration
  def self.up(database)
    database.create_table(
      :charge,
      {
        posted_date: :datetime,
        remote_id: :string,
        amount: :float,
        description: :string,
        vendor_id: :integer,
        credit_card_id: :integer
      }
    )
  end

  def self.down(database)
    database.drop_table(:charge)
  end
end
