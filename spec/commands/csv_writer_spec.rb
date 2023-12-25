require_relative '../../app/objects/obj'
require_relative '../../app/commands/mixins/display.rb'
require_relative '../../app/commands/csv.rb'
require 'csv'

class CsvObj < Obj
  def self.default_display
    {
      sym_sets: {
        default: [:x, :y]
      },
      fields: {
        id: { width: 10, type: :string, title: 'ID' },
        x: { width: 10, type: :string, title: 'x' },
        y: { width: 15, type: :float, title: 'y', format: '%.2f' },
      }
    }
  end

  def initialize(x, y)
    super(:csv_obj, {x: x, y: y})
  end
end

describe CsvWriter do
  let(:filename) { 'test.csv' }
  let(:csv_obj_1) { CsvObj.new("hello", 5.4) }

  context 'when not grouped' do
    let(:csv_objs) { [csv_obj_1] }

    it 'generates a csv'  do
      CsvWriter.run(filename, csv_objs)
      expect(CSV.read(filename)).to eq([
        ['x', 'y'],
        ['hello', '5.40']
      ])
    end
  end

  context 'when grouped' do
    let(:csv_obj_2) { CsvObj.new("goodbye", 6.912) }
    let(:csv_obj_3) { CsvObj.new("hello", 3.2) }

    let(:csv_objs) { { 'hello' => [csv_obj_1, csv_obj_3], 'goodbye' => [csv_obj_2] } }

    it 'generates a csv'  do
      CsvWriter.run(filename, csv_objs)
      expect(CSV.read(filename)).to eq([
        ['x', 'y'],
        ['hello', '5.40'],
        ['hello', '3.20'],
        [' '],
        ['x', 'y'],
        ['goodbye', '6.91'],
        [' '],
      ])
    end
  end
end
