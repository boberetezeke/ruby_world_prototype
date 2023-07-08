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
      context 'before assignment' do
        it 'returns an empty array' do
          a = A.new(1,2)
          expect(a.bs).to eq([])
        end
      end

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
          expect(a.bs.to_a).to eq([b])
        end

        it 'works when using a push' do
          a = A.new(1,2)
          b = B.new(3)
          a.bs.push(b)
          expect(a.bs).to eq([b])
        end

        it 'works when using a <<' do
          a = A.new(1,2)
          b = B.new(3)
          a.bs << b
          expect(a.bs).to eq([b])
        end

        it 'works when using delete' do
          a = A.new(1,2)
          b1 = B.new(3)
          b2 = B.new(4)

          a.bs = [b1, b2]
          expect(a.bs).to match_array([b1, b2])

          a.bs.delete(b1)
          expect(a.bs).to eq([b2])
        end

        it 'transfers from one owner to another if added to other owner' do
          a1 = A.new(1,2)
          a2 = A.new(3,4)
          b1 = B.new(3)
          b2 = B.new(4)

          a1.bs = [b1]
          a2.bs = [b2]

          a1.bs.push(b2)

          expect(a1.bs).to match_array([b1, b2])
          expect(a2.bs).to match_array([])
        end

        it 'allows mapping using enumeration' do
          a = A.new(1,2)
          b1 = B.new(3)
          b2 = B.new(4)

          a.bs = [b1, b2]
          expect(a.bs.map{|b| b.z}).to match_array([3, 4])
        end
      end
    end
  end
end
