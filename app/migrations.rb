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

    def self.register_classes(db, classes)
      classes.each {|klass| db.register_class(klass) }
    end
  end
end
