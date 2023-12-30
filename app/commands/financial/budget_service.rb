module Financial
  class BudgetService
    def initialize(db)
      @db = db
    end

    def self.weeks_in_month(date)
      date = Date.new(date.year, date.month, 1)
      weeks = []
      month = date.month
      week_start = date.cwday
      week_index = 1
      # if the first day is Thursday or later
      if week_start >= 4 # Thursday
        # then put with first week
        end_date = date + ((8 - week_start) + 6)
      else
        # else the first week is a week by itself
        end_date = date + (7 - week_start)
      end

      weeks.push([week_index, date..end_date])
      date = end_date + 1
      loop do
        week_index += 1
        end_date = date + 6
        if end_date.month != month
          end_date = date + 1
          loop do
            break if (end_date + 1).month != month
            end_date += 1
          end
        end
        weeks.push([week_index, date..end_date])
        date += 7
        break if date.month != month
      end

      if weeks.size > 4
        weeks[3][1] = (weeks[3][1].begin)..(weeks[4][1].end)
        weeks.pop
      end
      weeks
    end

    def matching_charges(budget_target)
      @db.charges.select do |charge|
        Obj::Tag.tags_match?(budget_target.tags, charge.tags)
      end
    end

    def current_month
      Time.now.month
    end

    def calc_amounts(date)
      @db.budget_targets.select{ |bt| bt.month == current_month }.each do |budget_target|
        calc_amounts_for_budget_target(date, budget_target)
      end
    end

    def self.days_in_month(date)
      month = date.month
      date = Date.new(date.year, date.month, 28)
      return 28 if (date + 1).month != month
      return 29 if (date + 2).month != month
      return 30 if (date + 3).month != month
      return 31
    end

    def calc_amounts_for_budget_target(date, budget_target)
      weeks = self.class.weeks_in_month(date)
      current_month = date.month
      budget_target.calc_amount = 0
      (1..4).each do |index|
        budget_target.send("week_#{index}_calc_amount=", 0)
        date_range = weeks[index-1][1]
        num_days = date_range.end - date_range.begin + 1
        week_amount = budget_target.amount * (num_days / self.class.days_in_month(date))
        budget_target.send("week_#{index}_amount=", week_amount)
      end

      @db.charges.select{ |ch| ch.posted_date.month == current_month }.each do |charge|
        if Obj::Tag.tags_match?(budget_target.tags, charge.tags)
          budget_target.calc_amount += charge.amount
          weeks.each do |week_index, date_range|
            if date_range.include?(charge.posted_date)
              week_attr = "week_#{week_index}_calc_amount"
              week_attr_value = budget_target.send(week_attr)
              budget_target.send("#{week_attr}=", week_attr_value + charge.amount)
            end
          end
        end
      end
    end
  end
end