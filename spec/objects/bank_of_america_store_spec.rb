require_relative '../../app/objects/obj'
require_relative '../../app/objects/obj/change'
require_relative '../../app/objects/obj/changes'
require_relative '../../app/objects/database'
require_relative '../../app/objects/database_adapter/in_memory'
require_relative '../../app/objects/database_adapter/sqlite_db'
require_relative '../../app/objects/database_adapter/sqlite_relationship'
require_relative '../../app/objects/store'

require_relative '../../app/migrations/add_charge_migration'
require_relative '../../app/migrations/add_credit_card_migration'
require_relative '../../app/migrations/add_vendor_migration'
require_relative '../../app/migrations/add_tag_migration'
require_relative '../../app/migrations/add_tagging_migration'

require_relative '../../app/objects/tag'
require_relative '../../app/objects/tagging'
require_relative '../../app/objects/taggable'

require_relative '../../app/objects/financial/bank_of_america_charge_rules'
require_relative '../../app/objects/financial/charge_rule'
require_relative '../../app/objects/charge'
require_relative '../../app/objects/vendor'
require_relative '../../app/objects/credit_card'

require_relative '../../app/objects/bank_of_america_store'

describe Obj::BankOfAmericaStore do
  describe '#sync' do
    let(:db) { Obj::Database.new }
    subject { Obj::BankOfAmericaStore.new(db, 'spec/fixtures')}

    let(:migrations) do [
      Obj::AddChargeMigration,
      Obj::AddVendorMigration,
      Obj::AddCreditCardMigration,
      Obj::AddTaggingMigration,
      Obj::AddTagMigration,
    ]
    end

    before do
      allow(Obj::Database).to receive(:database_adapter).and_return(Obj::DatabaseAdapter::SqliteDb)
      db.connect
      Obj::Database.migrate(migrations, db)
      db.register_class(Obj::Charge)
      db.register_class(Obj::Tagging)
      db.register_class(Obj::Tag)
      db.register_class(Obj::Vendor)
      db.register_class(Obj::CreditCard)

      db.add_obj(Obj::Tag.new('steve'))
      db.add_obj(Obj::Tag.new('expenses'))
      db.add_obj(Obj::Tag.new('entertainment'))

      subject.sync
    end

    after do
      Obj::Database.rollback(migrations, db)
    end

    it 'builds the charge objects' do
      expect(db.objs[:charge].size).to eq(4)
    end

    it 'builds the vendor objects' do
      expect(db.objs[:vendor].size).to eq(3)
    end

    it 'builds the credit_card objects' do
      expect(db.objs[:credit_card].size).to eq(1)
    end

    it 'has the correct info in the charge object' do
      db.info
      air_bnb_charge_1 = db.objs[:charge].values.find{|bp| bp.remote_id == '24492153192717417862520'}
      air_bnb_vendor = air_bnb_charge_1.vendor
      expect(air_bnb_charge_1.amount).to eq(-386.65)
      expect(air_bnb_vendor.charges.size).to eq(2)
    end

    it 'tags the charges appropriately' do
      kindle_charge = db.objs[:charge].values.find{|bp| bp.remote_id == '24692163192100636893179'}
      expect(kindle_charge.tags.map(&:name)).to match_array(['steve', 'expenses'])

      steve = db.objs[:tag].values.find{|tag| tag.name == 'steve'}
      expenses = db.objs[:tag].values.find{|tag| tag.name == 'expenses'}
      expect(steve.objs).to eq([kindle_charge])
      expect(expenses.objs).to eq([kindle_charge])
    end

    it 'changes tags if already tagged' do
      allow(subject).to receive(:charge_rules).and_return([
         Financial::ChargeRule.new(db, ['entertainment'], 'description',
                                   ->(charge) { /kindle/i.match(charge.vendor.name) })
      ])

      subject.sync

      kindle_charge = db.objs[:charge].values.find{|bp| bp.remote_id == '24692163192100636893179'}
      expect(kindle_charge.tags.map(&:name)).to match_array(['entertainment'])
    end
  end
end
