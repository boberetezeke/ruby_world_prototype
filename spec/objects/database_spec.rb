require_relative '../../app/objects/obj'
require_relative '../../app/objects/database'
require 'yaml'

describe Obj::Database do
  subject { Obj::Database.new }

  describe '#serialize' do
    it 'writes the database to disk' do
      hash = subject.serialize
      expect(hash[:version]).to eq(2)
    end
  end

  describe '#deserialize' do
    it 'writes the database to disk' do
      subject.deserialize({ objs: [], version: 2 })
      expect(subject.objs).to eq([])
    end
  end

  describe '#write' do
    it 'writes the database to disk' do
      subject.write
      yaml = YAML.load(File.read('db.yml'))
      expect(yaml[:version]).to eq(2)
    end
  end
end