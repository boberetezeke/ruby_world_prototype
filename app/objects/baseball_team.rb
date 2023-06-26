class Obj::BaseballTeam < Obj
  has_many :baseball_players, :basebase_player, :baseball_team_id

  def initialize(name)
    super(:baseball_team, {name: name})
  end
end
