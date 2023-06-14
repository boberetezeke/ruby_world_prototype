def camelize(string, uppercase_first_letter = true)
  if uppercase_first_letter
    string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
  else
    string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
  end
  string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
end

PAGE_SIZE = 10

def f(objs)
  if objs.empty?
    puts "no objects to display"
    return
  end

  obj_types = objs.map{|o| o.class.to_s}.uniq
  if obj_types.size == 1
    display = objs.first.class.default_display
    ids = display[:sym_sets][:default]
    fields = ids.map do |full_id|
      d = display
      last_id = full_id
      if full_id.is_a?(Array)
        d = eval("Obj::" + camelize(full_id[-2].to_s)).default_display
        last_id = full_id[-1]
      end
      [last_id, d[:fields][last_id], full_id]
    end

    format = fields.map{ |id, f, _| "%-#{f[:width]}s" }.join(' ')
    titles = fields.map{ |id, f, _| f[:title] }
    data_lambda = ->(obj){
      fields.map do |id, f, full_id|
        if full_id.is_a?(Array)
          val = obj
          full_id.each{|sym| val = val&.send(sym) }
        else
          val = obj.send(id)
        end

        case f[:type]
        when :string
          val
        when :float
          f[:format] % [val]
        end
      end
    }

    puts(format % titles)
    total = objs.size
    start_index = 0
    loop do
      end_index = start_index + PAGE_SIZE - 1
      end_index = total - 1 if end_index > total
      objs[start_index..end_index].each do |obj|
        puts(format % data_lambda.call(obj) )
      end

      puts "(p - previous, q - quit, enter - next) #{start_index}-#{end_index} of #{total}: "
      s = gets
      break if s =~ /q/i
      if s =~ /p/i
        start_index -= PAGE_SIZE
        start_index = 0 if start_index < 0
      else
        if start_index + PAGE_SIZE < total
          start_index += PAGE_SIZE
        end
      end
    end
  else
    puts "all objects must be of the same type: #{obj_types}"
  end
end