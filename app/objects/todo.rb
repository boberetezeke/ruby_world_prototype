class Obj::Todo < Obj
  def initialize(title, due_date)
    super(:todo, {title: title, due_date: due_date, state: state})
  end

  def mark_as_done
    @state = :done
  end
end

