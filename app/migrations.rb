path = File.dirname(__FILE__)

load "#{path}/migrations/migrate_player_data_to_stats.rb"

module Migrations
  def self.migrations
    [
      MigratePlayerDataToStats
    ].map(&:to_s)
  end
end
