class Obj::BaseballTeam < Obj
  def initialize(name)
    super(:baseball_team, {name: name})
  end
end

