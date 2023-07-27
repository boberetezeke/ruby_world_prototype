def sql(action=nil)
  unless action
    if @old_logger
      puts "sql debug is OFF"
    else
      puts "sql debug is ON"
    end
    puts "USAGE: sql :on|:off"
    return
  end

  if action == :off
    if @old_logger
      puts "sql debug already OFF"
      return
    end
    @old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    puts "sql_debug OFF"
  else
    unless @old_logger
      puts "sql debug already ON"
      return
    end

    ActiveRecord::Base.logger = @old_logger
    @old_logger = nil
    puts "sql_debug ON"
  end
end