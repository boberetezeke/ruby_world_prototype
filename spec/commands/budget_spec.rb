require_relative '../../app/objects/obj'
require_relative '../../app/objects/database'
require_relative '../../app/commands/budget.rb'
require_relative '../../app/objects/tag'
require_relative '../../app/objects/tagging'
require_relative '../../app/objects/taggable'
require_relative '../../app/objects/budget_target'

describe Financial::Budget do
  subject { Financial::Budget.new(db) }
  let(:db) { Obj::Database.new }
  let(:personal) { 'personal' }
  let(:expenses) { 'expenses' }
  let(:tag_personal) { Obj::Tag.new(personal) }
  let(:tag_expenses) { Obj::Tag.new(expenses) }
  let(:budget_target) {
    Obj::BudgetTarget.new(
      Time.now.month,
      amount: 100,
      week_1_amount: 20,
      week_2_amount: 25,
      week_3_amount: 25,
      week_4_amount: 30,
      calc_amount: -75,
      week_1_calc_amount: -20,
      week_2_calc_amount: -25,
      week_3_calc_amount: -10,
      week_4_calc_amount: -20
    )
  }
  let(:tagging_personal) {
    tagging = Obj::Tagging.new
    tagging.tag = tag_personal
    tagging.taggable = budget_target
    tagging
  }
  let(:tagging_expenses) {
    tagging = Obj::Tagging.new
    tagging.tag = tag_expenses
    tagging.taggable = budget_target
    tagging
  }

  context 'no args' do
    it 'displays no budget targets with no arguments and no budget targets' do
      expect(subject.run).to eq("No budget targets set for current month: #{Time.now.month}")
    end

    it 'displays a budget target that exists' do
      db.add_obj(tag_personal)
      db.add_obj(tag_expenses)

      db.add_obj(budget_target)
      db.add_obj(tagging_personal)
      db.add_obj(tagging_expenses)

      ret, output = subject.run

      #                                   1         2         3         4         5         6         7         8
      #                          123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789
      expect(output).to eq("personal,expenses  100(75.00%)  20(100.00%)  25(100.00%)  25(40.00%)   30(66.67%)  ")
      expect(ret).to eq([budget_target])
    end
  end

  context 'set budget' do
    it "doesn't sets a budget target if tags can't be found" do
      ret, errors = subject.run(:set, [personal, expenses], 100)
      expect(ret).to be_nil
      expect(errors).to eq("tag(s) not found: personal, expenses")
    end

    it "doesn't set a budget target if only one tag is found" do
      db.add_obj(tag_personal)
      ret, errors = subject.run(:set, [personal, expenses], 100)
      expect(ret).to be_nil
      expect(errors).to eq("tag(s) not found: #{expenses}")
    end

    it "sets a budget target if tags can be found" do
      db.add_obj(tag_personal)
      db.add_obj(tag_expenses)
      ret, errors = subject.run(:set, [personal, expenses], 100)
      expect(ret).not_to be_nil
      expect(ret.class).to eq(Obj::BudgetTarget)
      expect(errors).to be_nil
      expect(db.budget_targets.size).to eq(1)
    end
  end

  context 'rm budget' do
    it "handles the budget not existing" do
      ret, errors = subject.run(:rm, [personal, expenses])
      expect(ret).to be_nil
      expect(errors).to eq("tag(s) not found: #{personal}, #{expenses}")
    end

    it "handles the budget not existing with tags" do
      db.add_obj(tag_personal)
      db.add_obj(tag_expenses)

      ret, errors = subject.run(:rm, [personal, expenses])
      expect(ret).to be_nil
      expect(errors).to eq("can't find budget_target with tags: #{personal}, #{expenses}")
    end

    it "removes a budget target if tags can be found" do
      db.add_obj(tag_personal)
      db.add_obj(tag_expenses)

      db.add_obj(budget_target)
      db.add_obj(tagging_personal)
      db.add_obj(tagging_expenses)

      ret, errors = subject.run(:rm, [personal, expenses])
      expect(ret).to be_nil
      expect(errors).to be_nil
      expect(db.budget_targets.size).to eq(0)
    end
  end
end
