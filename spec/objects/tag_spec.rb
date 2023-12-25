require_relative '../../app/objects/obj'
require_relative '../../app/objects/tag'
require_relative '../../app/objects/tagging'
require_relative '../../app/objects/taggable'

class Obj::Car < Obj
  include Taggable

  def initialize(color)
    super(:car, {color: color})
  end
end

describe Obj::Tag do
  context 'tags' do
    it 'creates a tagging to a tag' do
      tag = Obj::Tag.new('my-tag')
      tagging = Obj::Tagging.new
      tagging.tag = tag
      expect(tag.taggings).to eq([tagging])
    end

    it 'attaches a tag to an object' do
      car = Obj::Car.new('red')
      tagging = Obj::Tagging.new
      tagging.taggable = car
      expect(car.taggings).to eq([tagging])
    end

    it 'goes from tag to object and object to tag' do
      car = Obj::Car.new('red')
      tag = Obj::Tag.new(name: 'red things')

      tagging = Obj::Tagging.new
      tagging.taggable = car
      tagging.tag = tag

      expect(tag.objs).to eq([car])
      expect(car.tags).to eq([tag])
    end
  end
end
