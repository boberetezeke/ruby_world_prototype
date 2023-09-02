IRB.conf[:PROMPT_MODE] = :DEFAULT
load 'local_db.rb'

def self.to_s
  @db.tag_context
end
