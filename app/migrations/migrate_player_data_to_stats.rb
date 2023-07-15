class MigratePlayerDataToStats
  def self.up(database)
    return unless database.objs[:baseball_player]

    database.objs[:baseball_player].values.each do |bp|
      next unless bp.attrs[:fantrax_stats].nil?

      bp.attrs[:fantrax_stats] = [
        Obj::FantraxStat.new(
          Date.new(2023,6,14),
          7,
          bp.fantasy_ppg,
          bp.fantasy_pts,
          bp.roster_pct,
          bp.roster_pct_chg
        )
      ]
      bp.remove_keys(:fantasy_ppg, :fantasy_pts, :roster_pct, :roster_pct_chg)
    end
  end
end