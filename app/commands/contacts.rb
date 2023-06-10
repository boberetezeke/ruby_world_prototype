def contacts
  format = "%-35s %-20s %-20s %-20s"
  puts(format % ['id', 'name', 'phone', 'email'])
  cs = @db.objs[:contact]
  return if cs.nil?
  cs.each_value do |contact|
    puts(format % [contact.id, contact.name, contact.phone, contact.email])
  end
  nil
end

