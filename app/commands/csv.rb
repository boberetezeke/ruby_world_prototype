require 'csv'

class CsvWriter
  include Obj::Mixins::Display

  def self.run(filename, objs, *args, **hargs)
    cols = args + hargs.to_a.map{|k,v| {k => v}}
    csv_writer = new(filename)

    if objs.empty?
      return [filename, "no objects to display"]
    end

    if objs.is_a?(Hash)
      group_by_obj_types = objs.map do |_, v|
        v.map{|o| o.class.to_s}.uniq
      end.uniq
      if group_by_obj_types.size != 1
        return [filename, "all grouped by types must be the same"]
      else
        num_rows = csv_writer.write_grouped_objs(objs, cols)
      end
    elsif objs.is_a?(Array)
      obj_types = objs.map{|o| o.class.to_s}.uniq
      if obj_types.size == 1
        num_rows = csv_writer.write_objs(objs, cols)
      else
        return [filename, "all objects must be of the same type: #{obj_types}"]
      end
    else
      return [filename, "must be either an array or a hash of arrays"]
    end

    return [filename, "Wrote #{num_rows} rows to #{filename}"]
  end

  def initialize(filename)
    @filename = filename
  end

  def formats(fields)
    fields.map{ |id, f, _| "%#{f[:format] ? f[:format] : 's'}" }
  end

  def titles(fields)
    fields.map{ |id, f, _| f[:title] }
  end

  def write_grouped_objs(grouped_objs, cols)
    all_keys = grouped_objs.keys
    CSV.open(@filename, "wb") do |csv|
      all_keys.each do |key|
        objs = grouped_objs[key]
        titles, data_lambda = objs_cols_to_titles_and_data_lambda(objs, cols)
        write_header_and_rows(csv, objs, titles, data_lambda)
        write_empty_row(csv)
      end
    end

    (grouped_objs.keys.size * 2) + grouped_objs.keys.sum{ |key| grouped_objs[key].size }
  end

  def write_objs(objs, cols)
    titles, data_lambda = objs_cols_to_titles_and_data_lambda(objs, cols)
    CSV.open(@filename, "wb") do |csv|
      write_header_and_rows(csv, objs, titles, data_lambda)
    end

    objs.size
  end

  def write_header_and_rows(csv, objs, titles, data_lambda)
    write_header(csv, titles)
    write_rows(csv, objs, data_lambda)
  end

  def write_empty_row(csv)
    csv << [' ']
  end

  def objs_cols_to_titles_and_data_lambda(objs, cols)
    display = objs.first.class.default_display
    if cols.empty?
      cols = display[:sym_sets][:default]
    end

    f = fields(cols, display)
    data_lambda = data_lambda(f)
    titles = titles(f)

    [titles, data_lambda]
  end

  def write_header(csv, titles)
    csv << titles
  end

  def write_rows(csv, objs, data_lambda)
    objs.each do |obj|
      csv << data_lambda.call(obj)
    end
  end
end

def csv(filename, objs, *args, **hargs)
  ret, output = CsvWriter.run(filename, objs, *args, **hargs)
  puts output if output
  ret
end
