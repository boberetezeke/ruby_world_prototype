require_relative '../../app/objects/obj'
require_relative '../../app/objects/database'
require_relative '../../app/objects/store'

require_relative '../../app/objects/tag'
require_relative '../../app/objects/tagging'
require_relative '../../app/objects/taggable'
require_relative '../../app/objects/charge'
require_relative '../../app/objects/vendor'
require_relative '../../app/objects/credit_card'

require_relative '../../app/objects/bank_of_america_store'

describe Obj::BankOfAmericaStore do
  describe '#sync' do
    let(:db) { Obj::Database.new }
    subject { Obj::BankOfAmericaStore.new(db, 'spec/fixtures')}

    before do
      db.add_obj(Obj::Tag.new('steve'))
      db.add_obj(Obj::Tag.new('expenses'))

      subject.sync
    end

    it 'builds the credit_charge objects' do
      expect(db.objs[:charge].size).to eq(4)
    end

    it 'builds the vendor objects' do
      expect(db.objs[:vendor].size).to eq(3)
    end

    it 'builds the credit_card objects' do
      expect(db.objs[:credit_card].size).to eq(1)
    end

    it 'has the correct info in the charge object' do
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
  end
end
