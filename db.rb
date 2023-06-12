require 'securerandom'
require 'yaml'

path = File.dirname(__FILE__)

load "#{path}/app/objects.rb"
load "#{path}/app/commands.rb"

@db = Obj::Database.read


