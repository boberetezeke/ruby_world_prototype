def q
  if @db.unsaved?
    puts "use q! to quit or save and then quit using q"
    return
  end

  exit
end

def q!
  if !@db.unsaved?
    puts "exiting with unsaved changes"
  end

  exit
end