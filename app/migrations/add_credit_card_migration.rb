class Obj::AddCreditCardMigration
  def self.up(database)
    database.create_table(
      :credit_card,
      {
        last_four_digits: :string
      }
    )
  end

  def self.down(database)
    database.drop_table(:credit_card)
  end
end
