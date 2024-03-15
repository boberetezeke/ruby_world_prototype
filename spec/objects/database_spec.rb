require_relative '../../app/objects/obj'
require_relative '../../app/objects/obj/changes'
require_relative '../../app/objects/obj/change'
require_relative '../../app/objects/database'
require_relative '../../app/objects/database_adapter/in_memory'
require_relative '../../app/objects/database_adapter/sqlite_db'
require_relative '../../app/migrations'
require 'yaml'

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

class CreateA
  def self.up(database)
    database.create_table(:a, {x: :string, y: string})
  end
end

class CreateB
  def self.up(database)
    database.create_table(:b, {z: :string})
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
        a = A.new(1,2)
        b = B.new(3)
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

    context 'when loading after save' do
      it 'load and save' do
        a = A.new(1,2)
        b = B.new(3)
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
end
