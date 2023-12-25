module Financial
  class ChargeRule
    attr_reader :tags, :description, :proc
    def initialize(db, tag_names, description, proc)
      db_tags = db.objs[:tag]
      return unless db_tags

      @tags = db_tags.values.select{|tag| tag_names.include?(tag.name)}
      @description = description
      @proc = proc
    end

    def match?(charge)
      return false unless @tags

      @proc.call(charge)
    end
  end
end


