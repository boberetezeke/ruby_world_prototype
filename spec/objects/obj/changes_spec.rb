require_relative '../../../app/objects/obj'
require_relative '../../../app/objects/obj/changes'
require_relative '../../../app/objects/obj/change'

describe Obj::Changes do
  subject { described_class.new }

  describe '#add' do
    it 'adds a change with no changes for a symbol' do
      subject.add(Obj::Change.new(:a, 1,2))
      expect(subject.for_sym(:a)).to eq(Obj::Change.new(:a, 1,2))
    end

    it 'adds a new change with there are two changes to the same symbol' do
      subject.add(Obj::Change.new(:a, 1,2))
      subject.add(Obj::Change.new(:a, 2,3))
      expect(subject.for_sym(:a)).to eq(Obj::Change.new(:a, 1,3))
    end

    it 'has no change when there are two changes back to the same value' do
      subject.add(Obj::Change.new(:a, 1,2))
      subject.add(Obj::Change.new(:a, 2,1))
      expect(subject.for_sym(:a)).to be_nil
    end
  end
end
