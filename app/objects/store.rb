class Obj::Store < Obj
  def initialize(status_proc: ->(str){ puts str })
    @status_proc = status_proc
  end

  def sync
  end

  def status_proc
    @status_proc
  end
end