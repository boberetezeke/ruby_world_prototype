require_relative '../../app/objects/obj'
require_relative '../../app/objects/database'
require_relative '../../app/objects/store'
require_relative '../../app/objects/fantrax_store'
require_relative '../../app/objects/baseball_player'
require_relative '../../app/objects/baseball_team'
require_relative '../../app/objects/fantasy_team'
require_relative '../../app/objects/fantrax_stat'
require_relative '../../app/objects/collection'

describe Obj::FantraxStore do
  describe '#sync' do
    let(:db) { Obj::Database.new }
    subject { Obj::FantraxStore.new(db, 'spec/fixtures')}

    before do
      subject.sync
    end

    it 'builds the baseball_player objects' do
      expect(db.objs[:baseball_player].size).to eq(5)
    end

    it 'builds fantasy_team objects' do
      expect(db.objs[:fantasy_team].size).to eq(4)
    end

    it 'builds baseball_team objects' do
      expect(db.objs[:baseball_team].size).to eq(3)
    end

    it 'builds fantrax_stat objects' do
      expect(db.objs[:baseball_player].map{|k,bp| bp.fantrax_stats.size}).to eq([2,2,2,2,2])
    end

    it 'has the correct stats in the fantrax object' do
      blake_snell = db.objs[:baseball_player].values.find{|bp| bp.name == 'Blake Snell'}
      blake_snell_stat = blake_snell.fantrax_stats.to_a.first
      expect(blake_snell_stat.fantasy_ppg).to eq(41)
      expect(blake_snell_stat.baseball_player).to eq(blake_snell)
    end
  end
end
