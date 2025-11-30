require_relative '../../../app/objects/obj'
require_relative '../../../app/objects/obj/changes'
require_relative '../../../app/objects/obj/change'
require_relative '../../../app/objects/database'
require_relative '../../../app/objects/database_adapter/in_memory'
require_relative '../../../app/migrations'
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

describe Obj::DatabaseAdapter::InMemoryDb do
  let(:db) { Obj::Database.new }
  subject { described_class.new(db) }

  describe '#serialize' do
    it 'writes the database to disk' do
      hash = subject.serialize
      expect(hash[:version]).to eq(described_class.current_version)
    end
  end

  describe '#deserialize' do
    it 'writes the database to disk' do
      subject.deserialize({ objs: [], version: described_class.current_version })
      expect(subject.objs).to eq([])
    end
  end

  describe '#write' do
    it 'writes the database to disk' do
      subject.write
      yaml = YAML.load(File.read('db.yml'))
      expect(yaml[:version]).to eq(described_class.current_version)
    end
  end

  describe '#unsaved?' do
    it 'returns false with a newly loaded database' do
      database = described_class.new(db)
      expect(database.unsaved?).to be_falsey
    end

    it 'returns true when an object is added to the database' do
      database = described_class.new(db)
      database.add_obj(A.new(1,2))
      expect(database.unsaved?).to be_truthy
    end

    it 'returns false when an object is added to the database and then saved' do
      database = described_class.new(db)
      database.add_obj(A.new(1,2))
      database.write
      expect(database.unsaved?).to be_falsy
    end

    it 'returns true when an object is changed' do
      database = described_class.new(db)
      database.add_obj(A.new(1,2))
      database.write
      a_obj = database.objs[:a].values.first
      a_obj.x = 10
      a_obj.save
      expect(database.unsaved?).to be_truthy
    end

    it 'returns false when an object attr is set but not changed' do
      database = described_class.new(db)
      database.add_obj(A.new(1,2))
      database.write
      a_obj = database.objs[:a].values.first
      a_obj.x = 1
      a_obj.save
      expect(database.unsaved?).to be_truthy
      database.write
      expect(database.unsaved?).to be_falsey
    end
  end

  describe '.read' do
    it 'reads the database file and deserializes it' do
      yml = {
        version: described_class.current_version,
        objs: {},
        tags: [],
        classes: {},
        migrations_applied: []
      }
      File.open('db.yml', 'w') {|f| f.write(yml.to_yaml) }
      database = described_class.read(db)

      expect(database.version_read).to eq(described_class.current_version)
    end
  end
end