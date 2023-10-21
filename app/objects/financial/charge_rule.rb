module Financial
  class ChargeRule
    attr_reader :tags, :proc
    def initialize(db, tag_names, proc)
      db_tags = db.objs[:tag]
      return unless db_tags

      @tags = db_tags.values.select{|tag| tag_names.include?(tag.name)}
      @proc = proc
    end

    def match?(charge)
      return false unless @tags

      @proc.call(charge)
    end
  end
end


