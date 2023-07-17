require_relative '../../app/objects/obj'
require_relative '../../app/objects/database'
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

describe Obj::Database do
  subject { Obj::Database.new }

  describe '#serialize' do
    it 'writes the database to disk' do
      hash = subject.serialize
      expect(hash[:version]).to eq(Obj::Database.current_version)
    end
  end

  describe '#deserialize' do
    it 'writes the database to disk' do
      subject.deserialize({ objs: [], version: Obj::Database.current_version })
      expect(subject.objs).to eq([])
    end
  end

  describe '#write' do
    it 'writes the database to disk' do
      subject.write
      yaml = YAML.load(File.read('db.yml'))
      expect(yaml[:version]).to eq(Obj::Database.current_version)
    end
  end

  describe '.read' do
    it 'reads the database file and deserializes it' do
      yml = {
        version: Obj::Database.current_version,
        objs: {},
        tags: [],
        migrations_applied: []
      }
      File.open('db.yml', 'w') {|f| f.write(yml.to_yaml) }
      database = described_class.read

      expect(database.version_read).to eq(Obj::Database.current_version)
    end
  end

  context 'when loading after save' do
    it 'load and save' do
      a = A.new(1,2)
      b = B.new(3)
      b.a = a

      subject.add_obj(a)
      subject.add_obj(b)

      subject.write
      database = Obj::Database.read

      a2 = database.objs[:a].values.first

      expect(a2.bs.to_a.size).to eq(1)
      expect(a2.bs.to_a.first.z).to eq(3)
    end
  end
end