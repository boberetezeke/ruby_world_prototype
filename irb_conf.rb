IRB.conf[:PROMPT_MODE] = :DEFAULT
puts 'in irb_conf'
load 'local_db.rb'


def self.to_s
  @db.tag_context
end
