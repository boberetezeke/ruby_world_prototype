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

class C < Obj
  belongs_to :dable, :dable_id, polymorphic: true, inverse_of: :cs
  def initialize(x)
    super(:c, {x: x})
  end
end

class D1 < Obj
  has_many :cs, :c, :dable_id, as: :dable
  def initialize(y)
    super(:d1, {y: y})
  end
end

class D2 < Obj
  has_many :cs, :c, :dable_id, as: :dable
  def initialize(z)
    super(:d2, {z: z})
  end
end

class E < Obj
  has_many :fs, :f, :e_id, inverse_of: :e
  has_many :gs, nil, nil, through: :fs, through_next: :g

  def initialize(e)
    super(:e, {e: e})
  end
end

class F < Obj
  belongs_to :e, :e_id, inverse_of: :fs
  belongs_to :g, :g_id, inverse_of: :fs

  def initialize(f)
    super(:f, {f: f})
  end
end

class G < Obj
  has_many :fs, :f, :g_id, inverse_of: :g

  def initialize(g)
    super(:g, {g: g})
  end
end

class I < Obj
  has_many :js, :j, :i_id, inverse_of: :i
  has_many :ks, nil, nil, through: :js, through_next: :ks

  def initialize(i)
    super(:i, {i: i})
  end
end

class J < Obj
  has_many :ks, :k, :j_id, inverse_of: :j
  belongs_to :i, :i_id, inverse_of: :js

  def initialize(j)
    super(:j, {j: j})
  end
end

class K < Obj
  belongs_to :j, :j_id, inverse_of: :ks

  def initialize(k)
    super(:k, {k: k})
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

  describe '#dup' do
    it 'copies attributes over' do
      a1 = A.new(1,2)
      a2 = a1.dup
      expect(a1.attrs).to eq(a2.attrs)
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

      context 'polymorphic belongs tos' do
        it 'gets both objects from D1 to D2 with assigning to d1, d2' do
          c1 = C.new(1)
          c2 = C.new(1)
          d = D1.new(2)

          d.cs = [c1, c2]

          expect(d.cs).to match_array([c1, c2])
        end

        it 'gets both objects from D1 to D2 when assigning to c' do
          c1 = C.new(1)
          c2 = C.new(1)
          d = D1.new(2)

          c1.dable = d
          c2.dable = d

          expect(d.cs).to match_array([c1, c2])
        end
      end

      context 'has_many throughs' do
        it 'accesses objects through a belongs_to' do
          e = E.new(1)
          f = F.new(2)
          g = G.new(3)

          f.e = e
          f.g = g

          gs = e.gs
          expect(gs).to eq([g])
        end

        it 'accesses objects through a has_many' do
          i = I.new(1)
          j = J.new(2)
          k = K.new(3)

          j.i = i
          k.j = j

          ks = i.ks
          expect(ks).to eq([k])
        end
      end
    end
  end
end
