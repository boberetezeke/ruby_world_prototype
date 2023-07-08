class Obj::FantraxStat < Obj
  belongs_to :baseball_player, :baseball_player_id, inverse_of: :fantrax_stats

  def self.default_display
    {
      sym_sets: {
        default: [:id, :fantasy_ppg, :fantasy_pts, :roster_pct, :roster_pct_chg]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        recorded_date: { width: 10, type: :date, title: 'stat type' },
        days_back: { width: 5, type: :integer, title: 'days back' },
        fantasy_ppg: { width: 10, type: :float, format: '%.2f', title: 'fpts/g' },
        fantasy_pts: { width: 10, type: :float, format: '%.2f', title: 'fpts' },
        roster_pct: { width: 10, type: :float, format: '%.2f', title: 'rstr %' },
        roster_pct_chg: { width: 10, type: :float, format: '%.2f', title: 'rstr chg' },
      }
    }
  end

  def initialize(recorded_date, days_back, fantasy_ppg, fantasy_pts, roster_pct, roster_pct_chg)
    super(:fantrax_stat, {
      recorded_date: recorded_date,
      days_back: days_back,
      fantasy_ppg: fantasy_ppg,
      fantasy_pts: fantasy_pts,
      roster_pct: roster_pct,
      roster_pct_chg: roster_pct_chg
    })
  end
end