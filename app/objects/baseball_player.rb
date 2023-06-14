class Obj::BaseballPlayer < Obj

  def self.default_display
    {
      sym_sets: {
        default: [:id, :name, :fantasy_ppg, :fantasy_pts, [:fantasy_team, :name]]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        name: { width: 20, type: :string, title: 'name' },
        fantasy_ppg: { width: 10, type: :float, format: '%.2f', title: 'fpts/g' },
        fantasy_pts: { width: 10, type: :float, format: '%.2f', title: 'fpts' }
      }
    }
  end

  def self.default_titles

  end

  def initialize(remote_id, name, baseball_team, positions, fantasy_team, age, fantasy_pts, fantasy_ppg, roster_pct, roster_pct_chg)
    super(:baseball_player, {
      remote_id: remote_id,
      name: name,
      baseball_team: baseball_team,
      positions: positions,
      fantasy_team: fantasy_team,
      age: age,
      fantasy_pts: fantasy_pts,
      fantasy_ppg: fantasy_ppg,
      roster_pct: roster_pct,
      roster_pct_chg: roster_pct_chg
    })
  end

  def self.from_csv(db, remote_id, name, team_name, positions, status, age, fantasy_pts, fantasy_ppg, roster_pct, roster_pct_chg)
    remote_id = remote_id
    name = name
    if team_name != "(N/A)"
      baseball_team = db.find_by(:baseball_team, name: team_name) || db.add_obj(Obj::BaseballTeam.new(team_name))
    else
      baseball_team = nil
    end
    positions = positions.split(/,/)
    if status != "FA"
      fantasy_team = db.find_by(:fantasy_team, name: status) || db.add_obj(Obj::FantasyTeam.new(status))
    else
      fantasy_team = nil
    end
    age = age.to_i
    fantasy_pts = fantasy_pts.to_f
    fantasy_ppg = fantasy_ppg.to_f
    roster_pct = roster_pct.to_f / 100.0
    m = /([+-])?([\.\d]+)?/.match(roster_pct_chg)
    if m[2]
      if m[1] == '-'
        roster_pct_chg = -(m[2].to_f)
      else
        roster_pct_chg = m[2].to_f
      end
    else
      roster_pct_chg = 0.0
    end
    roster_pct_chg = roster_pct_chg / 100.0
    player = new(remote_id, name, baseball_team, positions, fantasy_team, age, fantasy_pts, fantasy_ppg, roster_pct, roster_pct_chg)
    fantasy_team.players.add(player) if fantasy_team
    baseball_team.players.add(player) if baseball_team
    player
  end
end
