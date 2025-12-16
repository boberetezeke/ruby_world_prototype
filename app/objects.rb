path = File.dirname(__FILE__)

load "#{path}/objects/obj.rb"
load "#{path}/objects/obj/change.rb"
load "#{path}/objects/obj/changes.rb"
load "#{path}/objects/store.rb"
load "#{path}/objects/collection.rb"

load "#{path}/objects/database.rb"
load "#{path}/objects/database_adapter/in_memory_db.rb"
load "#{path}/objects/database_adapter/sqlite_db.rb"
load "#{path}/objects/tag.rb"

load "#{path}/objects/call.rb"
load "#{path}/objects/contact.rb"
load "#{path}/objects/email.rb"
load "#{path}/objects/note.rb"
load "#{path}/objects/tagging.rb"
load "#{path}/objects/taggable.rb"
load "#{path}/objects/tag.rb"

load "#{path}/objects/financial/charge_rule.rb"
load "#{path}/objects/financial/bank_of_america_charge_rules.rb"
load "#{path}/objects/charge.rb"
load "#{path}/objects/vendor.rb"
load "#{path}/objects/credit_card.rb"

load "#{path}/objects/bank_of_america_store.rb"

