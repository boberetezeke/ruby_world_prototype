require_relative '../../app/objects/obj'
require_relative '../../app/objects/obj/changes'
require_relative '../../app/objects/obj/change'
require_relative '../../app/objects/database'
require_relative '../../app/objects/database_adapter/in_memory_db'
require_relative '../../app/objects/database_adapter/sqlite_db'
require_relative '../../app/objects/database_adapter/sqlite_relationship'
require_relative '../../app/migrations'
require 'yaml'

class Obj::A < Obj
  type_sym :a
  has_many :bs, :b, :a_id, inverse_of: :a
  def initialize(x, y)
    super(:a, {x: x, y: y})
  end
end

class Obj::B < Obj
  type_sym :b
  belongs_to :a, :a_id, inverse_of: :bs
  def initialize(z)
    super(:b, {z: z})
  end
end

# Tagging
class Obj::C < Obj
  type_sym :c
  belongs_to :b, :b_id, inverse_of: :cs
  belongs_to :dable, :dable_id, polymorphic: true, inverse_of: :cs
  def initialize(x)
    super(:c, {x: x})
  end
end

# Taggable #1
class Obj::D1 < Obj
  type_sym :d1
  has_many :cs, :c, :dable_id, as: :dable
  has_many :bs, :b, nil, through: :cs,
           through_next: :b, through_back: :dable, through_type_sym: :c
  def initialize(y)
    super(:d1, {y: y})
  end
end

# Taggable #2
class Obj::D2 < Obj
  type_sym :d2
  has_many :cs, :c, :dable_id, as: :dable
  has_many :bs, :b, nil, through: :cs,
           through_next: :b, through_back: :dable, through_type_sym: :c
  def initialize(z)
    super(:d2, {z: z})
  end
end

class Obj::E < Obj
  type_sym :e
  has_many :fs, :f, :e_id, inverse_of: :e
  has_many :gs, nil, nil, through: :fs, through_next: :g, through_back: :e, through_type_sym: :f

  def initialize(e)
    super(:e, {e: e})
  end
end

# join table
class Obj::F < Obj
  type_sym :f
  belongs_to :e, :e_id, inverse_of: :fs
  belongs_to :g, :g_id, inverse_of: :fs

  def initialize(f)
    super(:f, {f: f})
  end
end

class Obj::G < Obj
  type_sym :g
  has_many :fs, :f, :g_id, inverse_of: :g
  has_many :es, nil, nil, through: :fs, through_next: :e, through_back: :g, through_type_sym: :f

  def initialize(g)
    super(:g, {g: g})
  end
end

class CreateA
  def self.up(database)
    database.create_table(:a, {x: :string, y: :string})
  end

  def self.down(database)
    database.drop_table(:a)
  end
end

class CreateB
  def self.up(database)
    database.create_table(:b, {z: :integer, a_id: :integer})
  end

  def self.down(database)
    database.drop_table(:b)
  end
end

class CreateC
  def self.up(database)
    database.create_table(:c, {x: :integer, b_id: :integer, dable_id: :integer, dable_type: :string})
  end

  def self.down(database)
    database.drop_table(:c)
  end
end

class CreateD1
  def self.up(database)
    database.create_table(:d1, {y: :integer, c_id: :integer})
  end

  def self.down(database)
    database.drop_table(:d1)
  end
end

class CreateD2
  def self.up(database)
    database.create_table(:d2, {z: :integer, c_id: :integer})
  end

  def self.down(database)
    database.drop_table(:d2)
  end
end

class CreateE
  def self.up(database)
    database.create_table(:e, {e: :integer, c_id: :integer})
  end

  def self.down(database)
    database.drop_table(:e)
  end
end

class CreateF
  def self.up(database)
    database.create_table(:f, {f: :integer, e_id: :integer, g_id: :integer})
  end

  def self.down(database)
    database.drop_table(:f)
  end
end

class CreateG
  def self.up(database)
    database.create_table(:g, {g: :integer})
  end

  def self.down(database)
    database.drop_table(:g)
  end
end

describe Obj::Database do
  subject {
    Obj::Database.new(database_adapter_class: database_adapter_class)
  }

  context 'when using in memory database' do
    let(:database_adapter_class) { Obj::DatabaseAdapter::InMemoryDb }

    context 'when loading after save' do
      let(:database) { described_class.load_or_reload(nil, database_filename: 'test_db.yml') }
      before do
        a = Obj::A.new(1,2)
        b = Obj::B.new(3)
        b.a = a

        e = Obj::E.new(1)
        f = Obj::F.new(2)
        g = Obj::G.new(3)
        f.e = e
        f.g = g

        subject.add_obj(a)
        subject.add_obj(b)
        subject.add_obj(e)
        subject.add_obj(f)
        subject.add_obj(g)

        subject.save
      end

      it 'has_many / belongs_to relationships reload correctly' do
        a2 = database.objs[:a].values.first

        expect(a2.bs.to_a.size).to eq(1)
        expect(a2.bs.to_a.first.z).to eq(3)
      end

      it 'has_many through relationship' do
        e2 = database.objs[:e].values.first
        g2 = database.objs[:g].values.first

        expect(e2.gs).to eq([g2])
        expect(g2.es).to eq([e2])
      end
    end
  end

  context 'when using in sqlite database' do
    let(:database_adapter_class) { Obj::DatabaseAdapter::SqliteDb }
    before do
      # allow(Obj::Database).to receive(:database_adapter).and_return(Obj::DatabaseAdapter::SqliteDb)
      subject.connect
      Obj::Database.migrate([
          CreateA, CreateB, CreateC, CreateD1, CreateD2, CreateE, CreateF, CreateG
        ], subject)
    end

    after do
      Obj::Database.rollback([
        CreateA, CreateB, CreateC, CreateD1, CreateD2, CreateE, CreateF, CreateG
      ], subject)
    end

    #
    # class SequelA < Sequel::Model(:a)
    #   one_to_many :sequel_bs, key: :a_id
    # end
    # class SequelB < Sequel::Model(:b)
    #   many_to_one :sequel_a, key: :a_id
    # end
    # SequelA.all.first.sequel_bs
    # SequelB.all.first.sequel_a
    #
    # like a relation, append _dataset
    #
    # SequelA.all.first.sequel_bs_dataset.where(z: '3').to_a
    #
    context 'when loading after save' do
      before do
        subject.register_class(Obj::A)
        subject.register_class(Obj::B)
        subject.register_class(Obj::C)
        subject.register_class(Obj::D1)
        subject.register_class(Obj::D2)
        subject.register_class(Obj::E)
        subject.register_class(Obj::F)
        subject.register_class(Obj::G)
      end

      it 'saves only a' do
        a = Obj::A.new(1,2)
        subject.add_obj(a)

        subject.save

        a2 = subject.find_by(:a, {id: a.db_id})

        expect(a2.x).to eq('1')
        # puts "at end of 'saves only a'"
      end

      it 'loads and saves a then b' do
        # puts "at beginning of 'loads and saves a then b'"
        a = Obj::A.new(1,2)
        b = Obj::B.new(3)

        b.a = a

        subject.add_obj(a)
        subject.add_obj(b)

        subject.save

        a2 = subject.find_by(:a, {id: a.db_id})

        expect(a2.bs.to_a.size).to eq(1)
        expect(a2.bs.to_a.first.z).to eq(3)
        # puts "at end of 'loads and saves a then b'"
      end

      it 'loads and saves b then a' do
        # puts "at beginning of 'loads and saves b then a'"
        a = Obj::A.new(1,2)
        b = Obj::B.new(3)

        b.a = a

        subject.add_obj(b)
        subject.add_obj(a)

        subject.save

        a2 = subject.find_by(:a, {id: a.db_id})

        expect(a2.bs.to_a.size).to eq(1)
        expect(a2.bs.to_a.first.z).to eq(3)
        # puts "at end of 'loads and saves b then a'"
      end

      it 'does handle many through' do
        e = Obj::E.new(1)
        f = Obj::F.new(2)
        g = Obj::G.new(3)
        f.e = e
        f.g = g

        subject.add_obj(e)
        subject.add_obj(f)
        subject.add_obj(g)

        subject.save

        e2 = subject.find_by(:e, {id: e.db_id})
        f2 = subject.find_by(:f, {id: f.db_id})
        g2 = subject.find_by(:g, {id: g.db_id})

        expect(e2.fs).to eq([f2])
        expect(g2.fs).to eq([f2])
        expect(e2.gs).to eq([g2])
        expect(g2.es).to eq([e2])
      end
    end
  end
end
