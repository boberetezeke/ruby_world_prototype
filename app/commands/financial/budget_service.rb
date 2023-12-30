module Financial
  class BudgetService
    def initialize(db)
      @db = db
    end

    def self.weeks_in_month(date)
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
  end
end