require_relative '../../app/objects/obj'
require_relative '../../app/objects/database'
require_relative '../../app/objects/store'
require_relative '../../app/objects/charge'
require_relative '../../app/objects/vendor'
require_relative '../../app/objects/credit_card'
require_relative '../../app/objects/bank_of_america_store'

describe Obj::BankOfAmericaStore do
  describe '#sync' do
    let(:db) { Obj::Database.new }
    subject { Obj::BankOfAmericaStore.new(db, 'spec/fixtures')}

    before do
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
  end
end
