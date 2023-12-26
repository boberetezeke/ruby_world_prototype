module Financial
  class Budget
    def initialize(db)
      @db = db
    end

    def run(*args, **hargs)
      if args.empty?
        display
      else
        command = args.shift
        case command
        when :set
          errors = validate_set(args)
          return errors if errors
          return set(@tags, @amount)
        when :rm
          errors = validate_rm(args)
          return errors if errors
          return rm(@tags)
        when :help
          return "                    display budget targets\n" +
                 "set [tags] amount   set a budget target\n" +
                 "rm  [tags]          remove budget target"
        else
          return "unknown sub-command: #{command}"
        end
      end
    end

    def validate_set(args)
      if args.size != 2
        return "set: wrong number of arguments. Got #{args.size}, expected 2"
      end

      errors = validate_tags(args[0])
      return errors if errors

      errors = validate_amount(args[1])
      return errors if errors

      nil
    end

    def validate_rm(args)
      if args.size != 1
        return "rm: wrong number of arguments. Got #{args.size}, expected 1"
      end

      errors = validate_tags(args[0])
      return errors if errors

      nil
    end

    def validate_tags(tag_names)
      @tags = tag_names.map do |tag_name|
        @db.find_by(:tag, {name: tag_name.to_s})
      end
      missing_tag_names = tag_names.map(&:to_s) - @tags.compact.map(&:name)
      return "tag(s) not found: #{missing_tag_names.join(', ')}" unless missing_tag_names.empty?

      nil
    end

    def validate_amount(amount)
      return "amount must a positive" unless amount > 0
      @amount = amount

      nil
    end

    def set(tags, amount)
      budget_target = find_budget_target(tags)
      unless budget_target
        budget_target = Obj::BudgetTarget.new(current_month)
        @db.add_obj(budget_target)
        # TODO: this should work
        # budget_target.tags = tags
        tags.each do |tag|
          tagging = Obj::Tagging.new
          tagging.tag = tag
          tagging.taggable = budget_target
          @db.add_obj(tagging)
        end
      end
      budget_target.amount = amount

      nil
    end

    def current_month
      Time.now.month
    end

    def find_budget_target(tags)
      budget_targets = @db.find_by(:budget_target, {month: current_month})
      return nil unless budget_targets
      budget_targets.find do |budget_target|
        Set.new(budget_target.map(&:name)) == Set.new(tags.map(&:name))
      end
    end

    def rm(tags)
      budget_target = find_budget_target(tags)
      return "can't find budget_target with tags: #{tags.map(&:name).join(', ')}"

      @db.rem_obj(budget_target)

      nil
    end

    def display
      budget_targets = @db.find_by(:budget_target, {month: current_month})
      if budget_targets.nil?
        return "No budget targets set for current month: #{current_month}"
      end
      budget_targets.map do |budget_target|
        "%-20s %.2f" % [budget_target.tags.map(&:tag_name).join(','), budget_target.amount]
      end.join("\n")
    end
  end
end

def budget(*args, **hargs)
  errors = Financial::Budget.new(@db).run(*args, **hargs)
  puts errors if errors
end