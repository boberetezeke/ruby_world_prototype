require_relative '../../app/objects/obj'

class A < Obj
  has_many :bs, :b, :a_id, inverse_of: :a
  def initialize(x, y)
    super(:a, {x: x, y: y})
  end
end

class B < Obj
  belongs_to :a, :a_id, inverse_of: :bs
  def initialize(z)
    super(:b, {z: z})
  end
end

describe Obj do
  context 'attributes' do
    it 'can retrieve initialized attributes' do
      a = A.new(1,2)
      expect(a.x).to eq(1)
      expect(a.y).to eq(2)
    end

    it 'can assign and retrieve attributes' do
      a = A.new(1,2)
      a.x = 3
      expect(a.x).to eq(3)
    end
  end

  context 'relationships' do
    context 'belongs_to' do
      it 'assigns and retrieves a belongs_to relationship' do
        a = A.new(1,2)
        b = B.new(3)
        b.a = a
        expect(b.a).to eq(a)
      end
    end

    context 'has_many' do
      context 'when assigning on the belongs_to side' do
        it 'assigns and retrieves a has_many relationship' do
          a = A.new(1,2)
          b = B.new(3)
          b.a = a
          expect(a.bs).to eq([b])
        end
      end

      context 'when assigning on the has_many side' do
        it 'assigns and retrieves a has_many relationship' do
          a = A.new(1,2)
          b = B.new(3)
          a.bs = [b]
          expect(a.bs).to eq([b])
        end
      end
    end
  end
end
