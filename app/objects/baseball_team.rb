class Obj::BaseballTeam < Obj
  def initialize(name)
    super(:baseball_team, {name: name, players: Obj::Collection.new(:baseball_player)})
  end
end

