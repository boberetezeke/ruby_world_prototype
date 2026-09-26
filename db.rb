require 'securerandom'
require 'yaml'

path = File.dirname(__FILE__)

load "#{path}/app/objects.rb"
load "#{path}/app/commands.rb"
load "#{path}/app/migrations.rb"

@db = Obj::Database.load_or_reload(@db, database_filename: 'data.sqlite3')
@db.connect()

Obj::Database.migrate(Obj::Setup.migrations, @db)
Obj::Setup.register_classes(@db, Obj::Setup.classes)


