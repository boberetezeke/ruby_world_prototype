def budget(month: Time.now.month, year: Time.now.year, include_largest_charges: false)
  charges_by_tags = by_tags(month, year: year, include_largest_charges: true)

  mnth_budget = month_budget(month, year)
  day_pct = (Time.now.day / Date.new(year, month, -1).day.to_f)
  total_amount = 0
  budgets = charges_by_tags.map do |chg_by_tag|
    if chg_by_tag[:tags]
      tags = chg_by_tag[:tags].join(':')
      amount = chg_by_tag[:amount]
      total_amount += amount
      tag_budget = mnth_budget[tags]
      res = {
        tags: tags,
        budget: 'NO BUDGET',
        amount: amount.round(2),
      }
      if tag_budget
        res[:budget] = tag_budget
        res[:diff] = (tag_budget - amount).round(2)

        if month == Time.now.month
          res[:percentage] = ((amount / (tag_budget.to_f / day_pct)) * 100).round(2)
        end
        if include_largest_charges
          res[:largest_charges] = chg_by_tag[:largest_charges]
        end
      end

      res
    end
  end.compact

  total_budget = mnth_budget.values.sum
  total_budget_pct = total_budget * day_pct
  budgets.push({
    tags: 'total',
    budget: total_budget_pct.round(2),
    amount: total_amount,
    diff: (total_budget_pct - total_amount).round(2),
    percentage: ((total_amount / (total_budget.to_f)) * 100).round(2),
    total_budget: total_budget
  })
end

def month_budget(month, year)
  Financial::BankOfAmericaChargeRules.budget_for(month, year).map{|tags, val| [tags.join(':'), val]}.to_h
end

def budget_report(month: Time.now.month, year: Time.now.year)
  budget_data = budget(month:, year:, include_largest_charges: true)
  lines = []

  lines << "# Overview"
  budget_data.each do |tag_info|
    lines << "* " + tag_info_str(tag_info)
  end

  lines  << "# Details"

  budget_data.each do |tag_info|
    lines << "* " + tag_info_str(tag_info)
    if tag_info[:largest_charges]
      tag_info[:largest_charges].each do |charge|
        lines << "  * " + charge_str(charge)
      end
    end
  end

  lines.join("\n")
end

def update_budget_note(db, month: Time.now.month, year: Time.now.year)
  budget_str = budget_report(month:, year:)
  if month == Time.now.month
    title = "Current Budget"
  else
    title = "#{month}/#{year} Budget"
  end
  joplin_note = @db.joplin_notes.find_by(title: title)
  if joplin_note
    joplin_note.body = budget_str
    db.update_obj(joplin_note)
    joplin_note.note.body = budget_str
    db.update_obj(joplin_note.note)
    puts "Note '#{title}' updated"
  else
    joplin_folder = @db.joplin_folders.find_by(title: "Budgets")
    joplin_note = Obj::JoplinNote.new(title, budget_str)
    note = Obj::Note.new(title, budget_str)
    joplin_note.note = note
    joplin_note.joplin_folder = joplin_folder
    db.add_obj(joplin_note)
    db.add_obj(note)
    puts "Note '#{title}' created"
  end
end

def tag_info_str(tag_info)
  "#{tag_info[:tags]}: #{tag_info[:budget]} - #{tag_info[:amount]} = #{tag_info[:diff]}"
end

def charge_str(charge)
  "#{charge[:posted_date].strftime('%m-%d-%Y')}: #{charge[:amount]} - #{charge[:description]}"
end

def move_current_budget
  rbw_data_path = ENV['RBW_DATA_PATH']
  cmd = "mv #{File.join(Dir.home, 'Downloads/currentTransaction_4765.csv')} #{File.join(Dir.home, rbw_data_path, 'imports/credit_card/CC_currentTransaction_4765.csv')}"
  puts "RUNNING: #{cmd}"
  system cmd
end

def credit_card_sync
  rbw_data_path = ENV['RBW_DATA_PATH']
  Obj::BankOfAmericaStore.new(@db, File.join(Dir.home, rbw_data_path, 'imports/credit_card')).sync
end