def tag(db, tag, objects)
  objects.each do |obj|
    next if obj.tags.include?(tag)

    tagging = Tagging.new
    tagging.tag = tag
    tagging.object = obj
    db.add_obj(tagging)
  end
end