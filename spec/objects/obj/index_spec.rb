require_relative '../../../app/objects/obj/index'

describe Index do
  subject { Index.new }

  describe '#add' do
    it 'adds a single value' do
      subject.add(:a, 1)
      expect(subject[:a]).to eq([1])
    end

    it 'adds two values' do
      subject.add(:a, 1)
      subject.add(:a, 2)
      expect(subject[:a]).to match_array([1, 2])
    end

    it 'adds two identical values only once' do
      subject.add(:a, 1)
      subject.add(:a, 1)
      expect(subject[:a]).to eq([1])
    end
  end

  describe '#remove' do
    it 'removes a value from a key' do
      subject.add(:a, 1)
      subject.remove(:a, 1)
      expect(subject[:a]).to eq([])
    end

    it 'removes a value from a key leaving other values' do
      subject.add(:a, 1)
      subject.add(:a, 2)
      subject.remove(:a, 2)
      expect(subject[:a]).to eq([1])
    end
  end

  describe '#update' do
    it 'updates the index' do
      subject.add(:a, 1)
      expect(subject[:a]).to eq([1])
      expect(subject[:b]).to eq([])

      subject.update(:a, :b, 1)
      expect(subject[:a]).to eq([])
      expect(subject[:b]).to eq([1])
    end
  end
end