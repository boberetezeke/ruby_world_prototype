class Obj::FantasyTeam < Obj
  def initialize(name)
    super(:fantasy_team, {name: name, players: Obj::Collection.new(:baseball_player)})
  end
end

