class Obj::AddChargeImportFileMigration
  def self.up(database)
    database.add_column(:charge, :import_filename, :string)
  end

  def self.down(database)
    database.remove_column(:charge, :import_filename)
  end
end
