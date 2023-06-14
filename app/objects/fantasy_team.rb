class Obj::FantasyTeam < Obj
  def self.default_display
    {
      sym_sets: {
        default: [:id, :name]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        name: { width: 20, type: :string, title: 'team name' },
      }
    }
  end
  def initialize(name)
    super(:fantasy_team, {name: name, players: Obj::Collection.new(:baseball_player)})
  end
end

