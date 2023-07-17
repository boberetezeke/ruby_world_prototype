def camelize(string, uppercase_first_letter = true)
  if uppercase_first_letter
    string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
  else
    string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
  end
  string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
end

module F
  def self.fields(cols, display)
    cols.map do |col_info|
      if col_info.is_a?(Hash)
        full_id = col_info.values.first
      else
        full_id = col_info
      end

      if full_id.is_a?(Proc)
        [nil, { title: '', type: :string, width: 20}, full_id]
      else
        d = display
        last_id = full_id
        if full_id.is_a?(Array)
          if full_id.size > 1
            d = eval("Obj::" + camelize(full_id[-2].to_s)).default_display
            last_id = full_id[-1]
          else
            full_id = full_id[0]
            last_id = full_id
          end
        end
        [last_id, d[:fields][last_id], full_id]
      end
    end
  end

  def self.data_lambda(fields)
    ->(obj){
      fields.map do |id, f, full_id|
        if full_id.is_a?(Proc)
          val = full_id.call(obj)
        elsif full_id.is_a?(Array)
          val = obj
          full_id.each{|sym| val = val&.send(sym) }
        else
          val = obj.send(id)
        end

        case f[:type]
        when :string
          val
        when :float
          val ? f[:format] % [val] : ''
        end
      end
    }
  end

  def self.format(fields)
    fields.map{ |id, f, _| "%-#{f[:width]}s" }.join(' ')
  end

  def self.titles(fields)
    fields.map{ |id, f, _| f[:title] }
  end

  def self.paginated_display(objs, format, data_lambda, page_size)
    total = objs.size
    start_index = 0
    loop do
      end_index = start_index + page_size - 1
      end_index = total - 1 if end_index > total
      objs[start_index..end_index].each do |obj|
        puts(format % data_lambda.call(obj) )
      end

      puts "(p - previous, q - quit, enter - next) #{start_index}-#{end_index} of #{total}: "
      s = gets
      break if s =~ /q/i
      if s =~ /p/i
        start_index -= page_size
        start_index = 0 if start_index < 0
      else
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

  obj_types = objs.map{|o| o.class.to_s}.uniq
  if obj_types.size == 1
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
  else
    puts "all objects must be of the same type: #{obj_types}"
  end
end