class Obj::Store
  def initialize
  end

  def sync
  end

  def status_proc
    ->(str) { puts str }
  end
end