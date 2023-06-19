class Obj::RotowireStat < Obj
  def self.default_display
    {
      sym_sets: {
        default: [:id, :fantasy_ppg, :fantasy_pts, :roster_pct, :roster_pct_chg]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        fantasy_ppg: { width: 10, type: :float, format: '%.2f', title: 'fpts/g' },
        fantasy_pts: { width: 10, type: :float, format: '%.2f', title: 'fpts' },
        roster_pct: { width: 10, type: :float, format: '%.2f', title: 'rstr %' },
        roster_pct_chg: { width: 10, type: :float, format: '%.2f', title: 'rstr chg' },
      }
    }
  end

  def initialize(stat_type, fantasy_ppg, fantasy_pts, roster_pct, roster_pct_chg)
    super(:fantrax_stat, {
      stat_type: stat_type,
      fantasy_ppg: fantasy_ppg,
      fantasy_pts: fantasy_pts,
      roster_pct: roster_pct,
      roster_pct_chg: roster_pct_chg
    })
  end
end