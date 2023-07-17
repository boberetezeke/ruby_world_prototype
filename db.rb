require 'securerandom'
require 'yaml'

path = File.dirname(__FILE__)

load "#{path}/app/migrations.rb"
load "#{path}/app/objects.rb"
load "#{path}/app/commands.rb"

@db = Obj::Database.read unless @db
# f players

Obj::FantraxStore.new(@db, '/home/stevetuckner/Projects/RubyWorld/ruby_world_prototype').sync
## Obj::FantraxStore.new(@db, '/Users/stevetuckner/Documents/Fantrax').sync

save

