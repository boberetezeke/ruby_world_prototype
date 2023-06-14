require 'securerandom'
require 'yaml'

path = File.dirname(__FILE__)

load "#{path}/app/objects.rb"
load "#{path}/app/commands.rb"

@db = Obj::Database.read

# Obj::FantraxStore.new(@db, '/home/stevetuckner/Projects/RubyWorld/ruby_world_prototype').sync

# save

