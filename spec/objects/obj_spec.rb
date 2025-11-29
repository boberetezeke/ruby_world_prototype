require_relative '../../app/objects/obj'
require_relative '../../app/objects/obj/change'
require_relative '../../app/objects/obj/changes'

class A < Obj
  has_many :bs, :b, :a_id, inverse_of: :a
  def initialize(x, y)
    super(:a, {x: x, y: y})
  end
end

# Tag
class B < Obj
  belongs_to :a, :a_id, inverse_of: :bs
  has_many :cs, :c,  :b_id, inverse_of: :b
  has_many :ds, nil, nil, through: :cs, through_next: :dable
  def initialize(z)
    super(:b, {z: z})
  end
end

# Tagging
class C < Obj
  belongs_to :b, :b_id, inverse_of: :cs
  belongs_to :dable, :dable_id, polymorphic: true, inverse_of: :cs
  def initialize(x)
    super(:c, {x: x})
  end
end

# Taggable #1
class D1 < Obj
  has_many :cs, :c, :dable_id, as: :dable
  has_many :bs, :b, nil, through: :cs,
           through_next: :b, through_back: :dable, through_type_sym: :c
  def initialize(y)
    super(:d1, {y: y})
  end
end

# Taggable #2
class D2 < Obj
  has_many :cs, :c, :dable_id, as: :dable
  has_many :bs, :b, nil, through: :cs,
           through_next: :b, through_back: :dable, through_type_sym: :c
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

    it 'records changes of initialization' do
      a = A.new(1,2)
      expect(a.changes.for_sym(:x)).to eq(Obj::Change.new(:x, nil, 1))
      expect(a.changes.for_sym(:y)).to eq(Obj::Change.new(:y, nil, 2))
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

    it 'copies the changes history over' do
      a1 = A.new(1,2)
      a2 = a1.dup
      expect(a1.changes).to eq(a2.changes)
    end
  end

  describe '==' do
    context 'when there is no db_id' do
      it 'matches on object_id if db_id is nil' do
        a1 = A.new(1,2)
        expect(a1).to eq(a1)
      end

      it 'does match on attributes' do
        a1 = A.new(1,2)
        a2 = A.new(1,2)
        expect(a1).to eq(a2)
      end
    end

    context 'when one entry has a db_id and another doesnt' do
      it 'when the first has a db_id value and the second is nil' do
        a1 = A.new(1,2)
        allow(a1).to receive(:db_id).and_return(1)
        a2 = A.new(2,3)
        allow(a2).to receive(:db_id).and_return(nil)
        expect(a1).not_to eq(a2)
      end

      it 'when the first db_id is nil and the second has a db_id value' do
        a1 = A.new(1,2)
        allow(a1).to receive(:db_id).and_return(nil)
        a2 = A.new(2,3)
        allow(a2).to receive(:db_id).and_return(1)
        expect(a1).not_to eq(a2)
      end
    end

    context 'when both entries have a db_id' do
      it 'does match when db_ids match' do
        a1 = A.new(1,2)
        allow(a1).to receive(:db).and_return(1)
        allow(a1).to receive(:db_id).and_return(1)
        a2 = A.new(2,3)
        allow(a2).to receive(:db).and_return(1)
        allow(a2).to receive(:db_id).and_return(1)
        expect(a1).to eq(a2)
      end

      it 'doesnt match when db_ids dont match' do
        a1 = A.new(1,2)
        allow(a1).to receive(:db_id).and_return(1)
        a2 = A.new(2,3)
        allow(a2).to receive(:db_id).and_return(2)
        expect(a1).not_to eq(a2)
      end
    end
  end

  context 'relationships' do
    context 'belongs_to' do
      before do
        @a = A.new(1,2)
        @b = B.new(3)
        @b.a = @a
      end

      it 'assigns and retrieves a belongs_to relationship' do
        expect(@b.a).to eq(@a)
      end

      it 'creates a change' do
        expect(@b.changes.for_sym(:a_id)).to eq(Obj::Change.new(:a_id, nil, @a.id))
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
        context 'when assigning and retrieving a has_many relationship' do
          before do
            @a = A.new(1,2)
            @b = B.new(3)
            @a.bs = [@b]
          end

          it 'assigns and retrieves a has_many relationship' do
            expect(@a.bs.to_a).to eq([@b])
          end

          it 'creates a change on the b object' do
            expect(@b.changes.for_sym(:a_id)).to eq(Obj::Change.new(:a_id, nil, @a.id))
          end
        end

        context 'when assigning, re-assigning and retrieving a has_many relationship' do
          before do
            @a = A.new(1,2)
            @b3 = B.new(3)
            @b4 = B.new(4)
            @b5 = B.new(5)
            @a.bs = [@b3, @b4]
            @a.bs = [@b4, @b5]
          end

          it 'assigns and retrieves a has_many relationship' do
            expect(@a.bs.to_a).to eq([@b4, @b5])
          end

          it 'creates a no change on the b3 object' do
            # creates no change because @be.a_id went from nil to @a.id back to nil
            expect(@b3.changes.for_sym(:a_id)).to be_nil
          end

          it 'creates a no change on the b4 object' do
            # failing because @be.a_id went from nil to @a.id back to nil
            expect(@b4.changes.for_sym(:a_id)).to eq(Obj::Change.new(:a_id, nil, @a.id))
          end

          it 'creates a no change on the b5 object' do
            # failing because @be.a_id went from nil to @a.id back to nil
            expect(@b5.changes.for_sym(:a_id)).to eq(Obj::Change.new(:a_id, nil, @a.id))
          end
        end

        context 'when assigning using push' do
          before do
            @a = A.new(1,2)
            @b = B.new(3)
            @a.bs.push(@b)
          end

          it 'assigns it correctly' do
            expect(@a.bs).to eq([@b])
          end

          # La eferia prado - March
          it 'creates a change on the b object' do
            expect(@b.changes.for_sym(:a_id)).to eq(Obj::Change.new(:a_id, nil, @a.id))
          end
        end

        context 'when using a <<' do
          before do
            @a = A.new(1,2)
            @b = B.new(3)
            @a.bs << @b
          end

          it 'assigns it correctly' do
            expect(@a.bs).to eq([@b])
          end

          it 'creates a change on the b object' do
            expect(@b.changes.for_sym(:a_id)).to eq(Obj::Change.new(:a_id, nil, @a.id))
          end
        end

        context 'when using assign has many then, delete' do
          before do
            @a = A.new(1,2)
            @b1 = B.new(3)
            @b2 = B.new(4)
            @a.bs = [@b1, @b2]
          end

          it 'has two array members' do
            expect(@a.bs).to match_array([@b1, @b2])
          end

          it 'creates a change on the b1 object' do
            expect(@b1.changes.for_sym(:a_id)).to eq(Obj::Change.new(:a_id, nil, @a.id))
          end

          it 'creates a change on the b2 object' do
            expect(@b2.changes.for_sym(:a_id)).to eq(Obj::Change.new(:a_id, nil, @a.id))
          end

          context 'when using delete' do
            before do
              @a.bs.delete(@b1)
            end

            it 'removes the one entry being deleted' do
              expect(@a.bs).to eq([@b2])
            end

            it 'removes change for b1 object' do
              expect(@b1.changes.for_sym(:a_id)).to be_nil
            end

            it 'change on the b2 object' do
              expect(@b2.changes.for_sym(:a_id)).to eq(Obj::Change.new(:a_id, nil, @a.id))
            end
          end
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
          c2 = C.new(2)
          d = D1.new(2)

          d.cs = [c1, c2]

          expect(d.cs).to match_array([c1, c2])
        end

        it 'gets both objects from D1 to D2 when assigning to c' do
          c1 = C.new(1)
          c2 = C.new(2)
          d = D1.new(2)

          c1.dable = d
          c2.dable = d

          expect(d.cs).to match_array([c1, c2])
        end

        it 'allows assigns to has_many throughs' do
          b1 = B.new(0)
          b2 = B.new(1)
          b3 = B.new(2)
          c1 = C.new(3)
          c2 = C.new(4)
          d1 = D1.new(5)
          d2 = D2.new(6)

          d1.bs = [b1, b2]
          d2.bs = [b2, b3]

          expect(d1.bs).to match_array([b1, b2])
          expect(d2.bs).to match_array([b2, b3])
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
