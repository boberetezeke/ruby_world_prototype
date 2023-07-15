require_relative '../../app/objects/obj'
require_relative '../../app/objects/database'
require_relative '../../app/migrations'
require 'yaml'

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
  describe '.migrate' do
    it 'applies migration if it hasnt been applied' do

    end
  end
end