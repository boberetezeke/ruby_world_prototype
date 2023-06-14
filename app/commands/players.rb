def players
  @db.objs[:baseball_player].values
  # format = "%-35s %-20s %-10s %-10s %-20s"
  # puts(format % ['id', 'name', 'fpts/gm', 'ftps', 'f_team'])
  # bps = @db.objs[:baseball_player]
  # return if bps.nil?
  # bps.values[0..5].each do |bp|
  #   puts(format % [bp.id, bp.name, "%.2f" % [bp.fantasy_ppg], bp.fantasy_pts, bp.fantasy_team&.name])
  # end
  # nil
end
