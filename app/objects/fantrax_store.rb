class Obj::FantraxStore < Store
  def initialize(db, directory)
    super()
    @db = db
    @directory = directory
  end

  def sync
    Dir["#{@directory}/*"].each do|fn|
      next unless fn =~ /7-days/

      lines = CSV.open(fn, headers: true).readlines
      baseball_players = lines[0..5].map do |row|
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
        Obj::BaseballPlayer.from_csv(@db, remote_id, name, team_name, positions, status, age, fantasy_pts, fantasy_ppg, roster_pct, roster_pct_chg)
      end

      baseball_players.each do |baseball_player|
        puts "looking for baseball player: #{baseball_player.remote_id}"
        db_baseball_player = @db.find_by(:baseball_player, { remote_id: baseball_player.remote_id })
        puts "db_baseball_player: #{db_baseball_player}"
        if !db_baseball_player.nil?
          baseball_player.update(db_baseball_player)
        else
          @db.add_obj(baseball_player)
        end
      end
    end
    nil
  end
end
