require_relative '../../app/objects/obj'
require_relative '../../app/objects/database'
require_relative '../../app/objects/tag'
require_relative '../../app/objects/tagging'
require_relative '../../app/objects/taggable'
require_relative '../../app/objects/budget_target'
require_relative '../../app/objects/charge'
require_relative '../../app/commands/financial/budget_service'

describe Financial::BudgetService do
  let(:charge_a_c_12_5) { Obj::Charge.new('abc1', 1.23, Date.new(2023,12,5)) }
  let(:charge_a_c_12_13) { Obj::Charge.new('abc2', 2.54, Date.new(2023,12,13)) }
  let(:charge_b_12_20) { Obj::Charge.new('abc3', 4.04, Date.new(2023,12,20)) }
  let(:tag_a) { Obj::Tag.new('a')}
  let(:tag_b) { Obj::Tag.new('b')}
  let(:tag_c) { Obj::Tag.new('c')}
  let(:charge_a_c_12_5_tagging_a) { Obj::Tagging.tag(tag_a, charge_a_c_12_5) }
  let(:charge_a_c_12_5_tagging_c) { Obj::Tagging.tag(tag_c, charge_a_c_12_5) }
  let(:charge_a_c_12_13_tagging_a) { Obj::Tagging.tag(tag_a, charge_a_c_12_13) }
  let(:charge_a_c_12_13_tagging_c) { Obj::Tagging.tag(tag_c, charge_a_c_12_13) }
  let(:charge_b_12_20_tagging_b) { Obj::Tagging.tag(tag_b, charge_b_12_20) }
  let(:budget_target_a_c) { Obj::BudgetTarget.new(12, amount: 31.00)}
  let(:budget_target_b) { Obj::BudgetTarget.new(12, amount: 31.00)}
  let(:budget_target_a_c_tagging_a) { Obj::Tagging.tag(tag_a, budget_target_a_c) }
  let(:budget_target_a_c_tagging_c) { Obj::Tagging.tag(tag_c, budget_target_a_c) }
  let(:budget_target_b_tagging_b) { Obj::Tagging.tag(tag_b, budget_target_b) }
  let(:db) { Obj::Database.new }
  subject{ Financial::BudgetService.new(db) }

  before do
    db.add_obj(tag_a)
    db.add_obj(tag_b)
    db.add_obj(tag_c)
    db.add_obj(charge_a_c_12_5)
    db.add_obj(charge_a_c_12_13)
    db.add_obj(charge_b_12_20)
    db.add_obj(budget_target_a_c)
    db.add_obj(budget_target_b)

    db.add_obj(charge_a_c_12_5_tagging_a)
    db.add_obj(charge_a_c_12_5_tagging_c)
    db.add_obj(charge_a_c_12_13_tagging_a)
    db.add_obj(charge_a_c_12_13_tagging_c)
    db.add_obj(charge_b_12_20_tagging_b)
    db.add_obj(budget_target_a_c_tagging_a)
    db.add_obj(budget_target_a_c_tagging_c)
    db.add_obj(budget_target_b_tagging_b)
  end

  describe '.days_in_month' do
    it 'returns the correct days for a Feb leap-year' do
      expect(described_class.days_in_month(Date.new(2020,2,1))).to eq(29)
    end

    it 'returns the correct days for a Feb non-leap-year' do
      expect(described_class.days_in_month(Date.new(2021,2,1))).to eq(28)
    end

    it 'returns the correct days for a Nov' do
      expect(described_class.days_in_month(Date.new(2023,11,1))).to eq(30)
    end

    it 'returns the correct days for a Dec' do
      expect(described_class.days_in_month(Date.new(2023,12,1))).to eq(31)
    end
  end

  describe '.weeks_in_month' do
    it 'returns the correct weeks for 12/2023' do
      result = described_class.weeks_in_month(Date.new(2023,12,1))
      expect(result).to eq(
        [
          [1, Date.new(2023,12,1)..Date.new(2023,12,10)],
          [2, Date.new(2023,12,11)..Date.new(2023,12,17)],
          [3, Date.new(2023,12,18)..Date.new(2023,12,24)],
          [4, Date.new(2023,12,25)..Date.new(2023,12,31)]
        ]
      )
    end

    it 'returns the correct weeks for 11/2023' do
      result = described_class.weeks_in_month(Date.new(2023,11,1))
      expect(result).to eq(
        [
          [1, Date.new(2023,11,1)..Date.new(2023,11,5)],
          [2, Date.new(2023,11,6)..Date.new(2023,11,12)],
          [3, Date.new(2023,11,13)..Date.new(2023,11,19)],
          [4, Date.new(2023,11,20)..Date.new(2023,11,30)]
        ]
      )
    end

    it 'returns the correct weeks for 10/2023' do
      result = described_class.weeks_in_month(Date.new(2023,10,1))
      expect(result).to eq(
        [
          [1, Date.new(2023,10,1)..Date.new(2023,10,8)],
          [2, Date.new(2023,10,9)..Date.new(2023,10,15)],
          [3, Date.new(2023,10,16)..Date.new(2023,10,22)],
          [4, Date.new(2023,10,23)..Date.new(2023,10,31)]
        ]
      )
    end

    it 'returns the correct weeks for 8/2023' do
      result = described_class.weeks_in_month(Date.new(2023,8,1))
      expect(result).to eq(
        [
          [1, Date.new(2023,8,1)..Date.new(2023,8,6)],
          [2, Date.new(2023,8,7)..Date.new(2023,8,13)],
          [3, Date.new(2023,8,14)..Date.new(2023,8,20)],
          [4, Date.new(2023,8,21)..Date.new(2023,8,31)]
        ]
      )
    end
  end

  describe '#matching_charges' do
    it 'returns the a-c charges' do
      expect(subject.matching_charges(budget_target_a_c)).to match_array([charge_a_c_12_5, charge_a_c_12_13])
    end

    it 'returns the b charges' do
      expect(subject.matching_charges(budget_target_b)).to match_array([charge_b_12_20])
    end
  end

  describe '#calc_amounts' do
    it 'calcs amounts correctly for budget_target_a_c' do
      subject.calc_amounts_for_budget_target(Date.new(2023,12,1), budget_target_a_c)
      expect(budget_target_a_c.calc_amount).to eq(3.77)
      expect(budget_target_a_c.week_1_calc_amount).to eq(1.23)
      expect(budget_target_a_c.week_2_calc_amount).to eq(2.54)
      expect(budget_target_a_c.week_3_calc_amount).to eq(0.00)
      expect(budget_target_a_c.week_4_calc_amount).to eq(0.00)
    end

    it 'calcs amounts correctly for budget_target_b' do
      subject.calc_amounts_for_budget_target(Date.new(2023,12,1), budget_target_b)
      expect(budget_target_b.amount).to eq(31.00)
      expect(budget_target_b.week_1_amount).to eq(10.00)
      expect(budget_target_b.week_2_amount).to eq(7.00)
      expect(budget_target_b.week_3_amount).to eq(7.00)
      expect(budget_target_b.week_4_amount).to eq(7.00)
      expect(budget_target_b.calc_amount).to eq(4.04)
      expect(budget_target_b.week_1_calc_amount).to eq(0.00)
      expect(budget_target_b.week_2_calc_amount).to eq(0.00)
      expect(budget_target_b.week_3_calc_amount).to eq(4.04)
      expect(budget_target_b.week_4_calc_amount).to eq(0.00)
    end
  end
end
