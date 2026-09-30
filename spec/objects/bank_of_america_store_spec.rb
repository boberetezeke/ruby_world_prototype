require_relative '../../app/objects'
require_relative '../../app/migrations'
require_relative '../support/database_support'

require 'yaml'

describe Obj::BankOfAmericaStore do
  # let(:db_type_class) { Obj::DatabaseAdapter::SqliteDb }
  db_type_all do
    describe '#sync' do
      # let(:db_test_filename) { 'test.sqlite3' }
      let(:db) { Obj::Database.new(database_adapter_class: db_type_class, filename: db_test_filename) }
      subject { Obj::BankOfAmericaStore.new(db, 'spec/fixtures')}

      before do
        # allow(Obj::Database).to receive(:database_adapter).and_return(Obj::DatabaseAdapter::SqliteDb)
        # allow(Obj::Database).to receive(:database_adapter).and_return(Obj::DatabaseAdapter::InMemoryDb)
        db.connect
        Obj::Database.migrate(Obj::Setup.migrations, db)
        Obj::Setup.register_classes(db, Obj::Setup.classes)

        db.add_obj(Obj::Tag.new('steve'))
        db.add_obj(Obj::Tag.new('expenses'))
        db.add_obj(Obj::Tag.new('entertainment'))

        subject.sync
      end

      after do
        Obj::Database.rollback(Obj::Setup.migrations, db)
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
        # db.info
        air_bnb_charge_1 = db.objs[:charge].values.find{|bp| bp.remote_id == '24492153192717417862520'}
        air_bnb_vendor = air_bnb_charge_1.vendor
        expect(air_bnb_charge_1.amount).to eq(-386.65)
        expect(air_bnb_vendor.charges.size).to eq(2)
      end

      it 'tags the charges appropriately' do
        kindle_charge = db.objs[:charge].values.find{|bp| bp.remote_id == '24692163192100636893179'}
        x = kindle_charge.tags
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
end
