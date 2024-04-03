require_relative '../../app/objects/obj'
require_relative '../../app/objects/obj/changes'
require_relative '../../app/objects/obj/change'
require_relative '../../app/objects/database'
require_relative '../../app/objects/database_adapter/in_memory'
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

class CreateA
  def self.up(database)
    database.create_table(:a, {x: :string, y: :string})
  end
end

class CreateB
  def self.up(database)
    database.create_table(:b, {z: :integer, a_id: :integer})
  end
end

describe Obj::Database do
  subject { Obj::Database.new }

  context 'when using in memory database' do
    before do
      allow(Obj::Database).to receive(:database_adapter).and_return(Obj::DatabaseAdapter::InMemoryDb)
    end

    context 'when loading after save' do
      it 'load and save' do
        a = Obj::A.new(1,2)
        b = Obj::B.new(3)
        b.a = a

        subject.add_obj(a)
        subject.add_obj(b)

        subject.save
        database = described_class.load_or_reload(nil)

        a2 = database.objs[:a].values.first

        expect(a2.bs.to_a.size).to eq(1)
        expect(a2.bs.to_a.first.z).to eq(3)
      end
    end
  end

  context 'when using in sqlite database' do
    before do
      allow(Obj::Database).to receive(:database_adapter).and_return(Obj::DatabaseAdapter::SqliteDb)
      Obj::Database.migrate([CreateA, CreateB], subject)
    end

    after do
      subject.close
      subject.unlink
      sleep 1
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
      it 'saves only a' do
        puts "at beginning of 'saves only a'"
        a = Obj::A.new(1,2)
        subject.register_class(Obj::A)
        subject.add_obj(a)

        subject.save

        a2 = subject.find_by(:a, {id: a.db_id})

        expect(a2.x).to eq('1')
        puts "at end of 'saves only a'"
      end

      it 'loads and saves a then b' do
        puts "at beginning of 'loads and saves a then b'"
        a = Obj::A.new(1,2)
        b = Obj::B.new(3)

        subject.register_class(Obj::A)
        subject.register_class(Obj::B)

        b.a = a

        subject.add_obj(a)
        subject.add_obj(b)

        subject.save

        a2 = subject.find_by(:a, {id: a.db_id})

        expect(a2.bs.to_a.size).to eq(1)
        expect(a2.bs.to_a.first.z).to eq(3)
        puts "at end of 'loads and saves a then b'"
      end

      it 'loads and saves b then a' do
        puts "at beginning of 'loads and saves b then a'"
        a = Obj::A.new(1,2)
        b = Obj::B.new(3)

        subject.register_class(Obj::A)
        subject.register_class(Obj::B)

        b.a = a

        subject.add_obj(b)
        subject.add_obj(a)

        subject.save

        a2 = subject.find_by(:a, {id: a.db_id})

        expect(a2.bs.to_a.size).to eq(1)
        expect(a2.bs.to_a.first.z).to eq(3)
        puts "at end of 'loads and saves b then a'"
      end

    end
  end
end
