def camelize(string, uppercase_first_letter = true)
  if uppercase_first_letter
    string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
  else
    string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
  end
  string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
end

module F
  extend Obj::Mixins::Display

  def self.format(fields)
    fields.map{ |id, f, _| "%-#{f[:width]}s" }.join(' ')
  end

  def self.titles(fields)
    fields.map{ |id, f, _| f[:title] }
  end

  def self.display_grouped_objs(grouped_objs, cols, page_size)
    all_keys = grouped_objs.keys
    total = all_keys.size
    index = 0
    loop do
      key = all_keys[index]
      objs = grouped_objs[key]
      prev_index = (index > 0) ? index - 1 : nil
      prev_key = (index > 0) ? all_keys[prev_index] : nil
      next_index = (index < total - 1) ? index + 1 : nil
      next_key = (index < total - 1) ? all_keys[next_index] : nil

      puts "----- #{key}"
      puts
      display_objs(objs, cols, page_size)

      puts
      puts "(p - previous (#{prev_index}) #{prev_key}, q - quit, enter - next (#{next_index}) #{next_key}) #{total}: "

      s = gets
      break if s =~ /q/i
      if s =~ /p/i
        index -= 1
        index = 0 if index < 0
      else
        break if index == total - 1
        if index
          index += 1
        end
      end
    end
  end

  def self.display_objs(objs, cols, page_size)
    display = objs.first.class.default_display
    if cols.empty?
      cols = display[:sym_sets][:default]
    end

    f = F.fields(cols, display)
    data_lambda = F.data_lambda(f)
    format = F.format(f)
    titles = F.titles(f)

    puts(format % titles)
    F.paginated_display(objs, format, data_lambda, page_size)
  end

  def self.paginated_display(objs, format, data_lambda, page_size)
    total = objs.size

    klass = objs.first.class
    total_obj =  klass.respond_to?(:total_obj) ? klass.total_obj(objs) :nil

    start_index = 0
    loop do
      end_index = start_index + page_size - 1
      end_index = total - 1 if end_index > total
      objs[start_index..end_index].each.with_index do |obj, index|
        puts(format % data_lambda.call(obj))
      end

      if total_obj
        puts
        puts(format % data_lambda.call(total_obj))
      end

      puts "(p - previous, q - quit, enter - next) #{start_index}-#{end_index} of #{total}: "
      s = gets
      break if s =~ /q/i
      if s =~ /p/i
        start_index -= page_size
        start_index = 0 if start_index < 0
      else
        break if end_index == total - 1
        if start_index + page_size < total
          start_index += page_size
        end
      end
    end
  end
end

# f players, display: {name: nil, fantasy_pts: ->(bp){ fp.fantasy_stats.first }, fantasy_ppg: ->(bp){ fp.fantasy_stats.first.fantasy_ppg }}
# f players, display: [:id, :name, [:fantasy_stats, :fantasy_pts]]]
#
def f(objs, *args, **hargs)
  page_size = 10

  # puts "args: #{args.inspect}"
  # puts "hargs: #{hargs.inspect}"

  cols = args + hargs.to_a.map{|k,v| {k => v}}

  if objs.empty?
    puts "no objects to display"
    return
  end

  if objs.is_a?(Hash)
    group_by_obj_types = objs.map do |_, v|
      v.map{|o| o.class.to_s}.uniq
    end.uniq
    if group_by_obj_types.size != 1
      puts "all grouped by types must be the same"
    else
      F.display_grouped_objs(objs, cols, page_size)
    end
  elsif objs.is_a?(Array)
    obj_types = objs.map{|o| o.class.to_s}.uniq
    if obj_types.size == 1
      F.display_objs(objs, cols, page_size)
    else
      puts "all objects must be of the same type: #{obj_types}"
    end
  else
    puts "must be either an array or a hash of arrays"
  end
end