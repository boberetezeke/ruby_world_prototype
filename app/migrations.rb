path = File.dirname(__FILE__)

load "#{path}/migrations/add_charge_migration.rb"
load "#{path}/migrations/add_credit_card_migration.rb"
load "#{path}/migrations/add_tag_migration.rb"
load "#{path}/migrations/add_tagging_migration.rb"
load "#{path}/migrations/add_vendor_migration.rb"

class Obj
  module Setup
    def self.migrations
      [
        Obj::AddChargeMigration,
        Obj::AddVendorMigration,
        Obj::AddCreditCardMigration,
        Obj::AddTaggingMigration,
        Obj::AddTagMigration,
      ]
    end
  end
end
