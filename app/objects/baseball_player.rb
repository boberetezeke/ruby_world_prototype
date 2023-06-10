class Obj::BaseballPlayer < Obj
  def initialize(remote_id, name, team_name, positions, fantasy_team, age, fantasy_pts, fantasy_ppg, roster_pct, roster_pct_chg)
    super(:baseball_player, {
      remote_id: remote_id,
      name: name,
      team_name: team_name,
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
      team_name = db.find_by(:baseball_team, name: team_name) || db.add_obj(Obj::BaseballTeam.new(team_name))
    else
      team_name = nil
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
    m = /([+-])?([\.\d]+)/.match(roster_pct_chg)
    if m[1] == '-'
      roster_pct_chg = -(m[2].to_f)
    else
      roster_pct_chg = m[2].to_f
    end
    roster_pct_chg = roster_pct_chg / 100.0
    new(remote_id, name, team_name, positions, fantasy_team, age, fantasy_pts, fantasy_ppg, roster_pct, roster_pct_chg)
  end
end
