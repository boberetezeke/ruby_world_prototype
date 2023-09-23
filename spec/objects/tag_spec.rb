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
  end
end
