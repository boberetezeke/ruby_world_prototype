def bt(num_lines=5)
  begin
    yield
  rescue Exception => e
    puts "ERROR: #{e}"
    puts e.backtrace[0..num_lines].join("\n")
  end
end