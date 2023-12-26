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

  it 'displays no budget targets with no arguments and no budget targets' do
    expect(subject.run).to eq("No budget targets set for current month: #{Time.now.month}")
  end

  it "doesn't sets a budget target if tags can't be found" do
    errors = subject.run(:set, ['personal', 'expenses'], 100)
    expect(errors).to eq("tag(s) not found: personal, expenses")
  end

  it "sets a budget target if tags can be found" do
    db.add_obj(Obj::Tag.new('personal'))
    db.add_obj(Obj::Tag.new('expenses'))
    errors = subject.run(:set, ['personal', 'expenses'], 100)
    expect(errors).to be_nil
    expect(db.budget_targets.size).to eq(1)
  end
end
