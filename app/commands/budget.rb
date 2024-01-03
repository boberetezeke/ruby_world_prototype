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
        when :calc
          return calc
        when :charges
          monthly = false
          errors = validate_charges(*args, **hargs)
          return [nil, errors] if errors

          monthly = true if hargs[:monthly]

          return charges(monthly: monthly)
        when :charges_by_tags
          return charges_by_tags
        when :help
          return help
        when :rm
          errors = validate_rm(args)
          return [nil, errors] if errors
          return rm(@tags)
        when :set
          errors = validate_set(args)
          return [nil, errors] if errors
          return set(@tags, @amount)
        when :show
          errors = validate_show(args)
          return [nil, errors] if errors
          return show(@tags)
        else
          return [nil, "unknown sub-command: #{command}"]
        end
      end
    end

    # ----------------- Command validators ---------------------
    def validate_charges(*args, **hargs)
      if !hargs.empty? && hargs.keys != [:monthly]
        return "only monthly option is available: #{hargs}"
      end
      if hargs.keys == [:monthly] && !([false, true].include?(hargs[:monthly]))
        return "monthly can only have true or false values"
      end

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

    def validate_show(args)
      if args.size != 1
        return "set: wrong number of arguments. Got #{args.size}, expected 1"
      end

      errors = validate_tags(args[0])
      return errors if errors

      nil
    end

    # ----------------- Validator helpers ---------------------
    def validate_amount(amount)
      return "amount must a positive" unless amount > 0
      @amount = amount

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

    # ----------------------- Commands ------------------------------
    def calc
      BudgetService.new(@db).calc_amounts(current_date)

      [nil, nil]
    end

    def charges(monthly: false)
      ret = BudgetService.new(@db).charges(current_date, monthly: monthly)

      [ret, nil]
    end

    def charges_by_tags(monthly: false)
      ret = BudgetService.new(@db).charges_by_tags(current_date, monthly: monthly)

      [ret, nil]
    end

    def display
      budget_targets = @db.where_by(:budget_target, {date: current_date})
      if budget_targets.empty?
        return "No budget targets set for current month: #{current_month_start}"
      end
      output = budget_targets.map do |budget_target|
        budget_target_str(budget_target)
      end.join("\n")

      [budget_targets, output]
    end

    def help
      return [
        nil,
        "                    display budget targets\n" +
          "set [tags] amount   set a budget target\n" +
          "rm  [tags]          remove budget target",
      ]
    end

    def rm(tags)
      budget_target = find_budget_target(tags)
      unless budget_target
        return [nil, "can't find budget_target with tags: #{tags.map(&:name).join(', ')}"]
      end

      @db.rem_obj(budget_target)

      [nil, nil]
    end

    def set(tags, amount)
      budget_target = find_budget_target(tags)
      unless budget_target
        budget_target = Obj::BudgetTarget.new(current_month_start)
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

      [budget_target, nil]
    end

    def show(tags, monthly: false)
      budget_target = find_budget_target(tags)

      output = ''
      if budget_target
        output << budget_target_str(budget_target) + "\n\n"
      end

      charges = BudgetService.new(@db).charges(current_date, monthly: monthly)
      output << charge_title_str + "\n"
      charges.each do |charge|
        output << charge_str(charge) + "\n"
      end

      [{budget_target: budget_target, charges: charges}, output]
    end

    # ------------------ Utility methods --------------------------------
    def amount_str(amount, calc_amount)
      return "" if amount.nil? || amount == 0
      return "%.0f" % [amount] if calc_amount.nil?
      "%.0f(%.2f%%)" % [amount, -((100.0 * calc_amount) / amount)]
    end

    def budget_target_str(budget_target)
      format = "%-19s%-12s %-12s %-12s %-12s %-12s"
      format % [
        budget_target.tags.map(&:name).join(','),
        amount_str(budget_target.amount, budget_target.calc_amount),
        amount_str(budget_target.week_1_amount, budget_target.week_1_calc_amount),
        amount_str(budget_target.week_2_amount, budget_target.week_2_calc_amount),
        amount_str(budget_target.week_3_amount, budget_target.week_3_calc_amount),
        amount_str(budget_target.week_4_amount, budget_target.week_4_calc_amount)
      ]
    end

    def charge_title_str
      charge_format % charge_titles
    end

    def charge_str(charge)
      charge_format % charge_data_lambda.call(charge)
    end

    def charge_fields
      display = Obj::Charge.default_display
      cols = display[:sym_sets][:default]
      F.fields(cols, display)
    end

    def charge_format
      F.format(charge_fields)
    end

    def charge_titles
      F.titles(charge_fields)
    end

    def charge_data_lambda
      F.data_lambda(charge_fields)
    end

    def current_month_start
      now = Time.now
      Date.new(now.year, now.month, 1)
    end

    def current_date
      Time.now.to_date
    end

    def find_budget_target(tags)
      budget_targets = @db.where_by(:budget_target, {date: current_month_start})
      return nil unless budget_targets

      budget_targets.find do |budget_target|
        Obj::Tag.tags_match?(budget_target.tags, tags)
      end
    end
  end
end

def budget(*args, **hargs)
  ret, output = Financial::Budget.new(@db).run(*args, **hargs)
  puts output if output
  ret
end