require 'csv'

class Obj::FantraxStore < Obj::Store
  def initialize(db, directory)
    super()
    @db = db
    @directory = directory
  end

  def sync
    Dir["#{@directory}/*"].each do|fn|
      m = /Fantrax-(\d+)-(\d+)-(\d+)--(\d+)-days/.match(fn)
      next unless m

      date = Date.new(m[1].to_i, m[2].to_i, m[3].to_i)
      days_back = m[4].to_i

      lines = CSV.open(fn, headers: true).readlines
      baseball_players = lines.map do |row|
        remote_id = row['ID']
        name = row['Player']
        team_name = row['Team']
        age = row['Age']
        positions = row['Position']
        status = row['Status']
        fantasy_pts = row['FPts']
        fantasy_ppg = row['FP/G']
        roster_pct = row['Ros %']
        roster_pct_chg = row['+/-']
        Obj::BaseballPlayer.from_csv(@db, date, days_back, remote_id, name, team_name, positions, status, age, fantasy_pts, fantasy_ppg, roster_pct, roster_pct_chg)
      end

      baseball_players_with_stats =
        baseball_players
          .select{|bp| bp.fantrax_stats.first.fantasy_pts > 0.0 }

      total = baseball_players_with_stats.size
      baseball_players_with_stats
        .each_with_index do |baseball_player, index|
        puts("%.2f" % [(index / total.to_f) * 100]) if index % 100 == 0
        # puts "looking for baseball player: #{baseball_player.remote_id}"

        db_baseball_player = find_or_add_baseball_player(baseball_player)
        db_baseball_team = find_or_add_baseball_team(baseball_player.baseball_team)
        db_fantasy_team = find_or_add_fantasy_team(baseball_player.fantasy_team)
        db_fantrax_stat = create_fantrax_stat(baseball_player)

        db_baseball_player.baseball_team = db_baseball_team if db_baseball_team
        db_baseball_player.fantasy_team = db_fantasy_team if db_fantasy_team
        db_baseball_player.fantrax_stats.push(db_fantrax_stat) unless find_fantrax_stat(db_fantrax_stat, db_baseball_player)
      end
    end
    nil
  end

  def find_or_add_baseball_player(baseball_player)
    db_baseball_player = @db.find_by(:baseball_player, { remote_id: baseball_player.remote_id })
    # puts "db_baseball_player: #{db_baseball_player}"
    if !db_baseball_player.nil?
      db_baseball_player.update(baseball_player)
    else
      db_baseball_player = baseball_player.dup
      @db.add_obj(db_baseball_player)
    end
    db_baseball_player
  end

  def find_or_add_baseball_team(baseball_team)
    return nil unless baseball_team

    db_baseball_team = @db.find_by(:baseball_team, { name: baseball_team.name })
    return db_baseball_team if db_baseball_team

    @db.add_obj(baseball_team.dup)
  end

  def find_or_add_fantasy_team(fantasy_team)
    return nil unless fantasy_team

    db_fantasy_team = @db.find_by(:fantasy_team, { name: fantasy_team.name })
    return db_fantasy_team if db_fantasy_team

    @db.add_obj(fantasy_team.dup)
  end

  def find_fantrax_stat(db_fantrax_stat, baseball_player)
    baseball_player.fantrax_stats.find do |fs|
      fs.recorded_date == db_fantrax_stat.recorded_date &&
        fs.days_back == db_fantrax_stat.days_back
    end
  end

  def create_fantrax_stat(baseball_player)
    fantrax_stat = baseball_player.fantrax_stats.first
    @db.add_obj(fantrax_stat.dup)
  end
end
