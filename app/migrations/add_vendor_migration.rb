class Obj::AddVendorMigration
  def self.up(database)
    database.create_table(
      :vendor,
      {
        name: :string,
        address: :string
      }
    )
  end

  def self.down(database)
    database.drop_table(:vendor)
  end
end
