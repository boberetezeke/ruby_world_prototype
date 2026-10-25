def tags_by_months(months, year: Time.now.year, tags_to_include: ['total'])
  month_tags = months.map do |month|
    {
      month: month,
      year: year,
      by_tags: by_tags(month, year: year)
    }
  end

  tags_by_months = {}
  month_tags.each do |month_tag|
    month_tag[:by_tags].each do |tag_info|
      if tag_info[:tags]
        tag_str = tag_info[:tags].join(':')
        tag_data = tag_info
      else
        tag_str = 'totals'
        tag_data = tag_info[:total]
      end

      tags_by_months[tag_str] ||= []
      tags_by_months[tag_str] << tag_data.slice(:amount, :num).merge(month: month_tag[:month], year: month_tag[:year])
    end

    if !tags_to_include.empty?
      tags_by_months.select! { |tag_str, _| tags_to_include.include?(tag_str) }
    end

    tags_by_months.each do |tag_str, tag_info|
      tags_by_months[tag_str] = tag_info.sort_by { |info| [info[:year], info[:month]] }
    end
  end

  tags_by_months
end

def by_tags(month, year: Time.now.year, include_largest_charges: false)
  totals_for_charges(charges_for_month(month, year: year), include_largest_charges: include_largest_charges)
end

def by_statement(month, year: Time.now.year, include_largest_charges: false)
  totals_for_charges(charges_for_statement(month_year_to_statement_name(month, year)), include_largest_charges: include_largest_charges)
end

def month_year_to_statement_name(month, year)
  Financial::BankOfAmericaChargeRules.month_year_to_statement_name(month, year)
end

def totals_for_charges(charges, include_largest_charges: false)
  tag_groups = Financial::BankOfAmericaChargeRules.rules.map { |rule| rule[0] }.uniq
  cbtg = charges_by_tag_groups(charges, tag_groups).map do |tags, chgs|
    sum = -chgs.sum(&:amount)
    {
      tags: tags,
      amount: sum,
      num: chgs.size,
    }.merge(include_largest_charges ? { largest_charges: largest_charges(chgs, sum) } : {})
  end.sort_by{|tags_and_amounts| tags_and_amounts[:amount]}
  negative_charges = charges.select{|c| c.amount < 0}
  cbtg.push({ total: { size: negative_charges.size, amount: -negative_charges.sum(&:amount) }})
end

def charges_for_statement(statement_name)
  @db.charges.where_by(import_filename: statement_name)
end


def largest_charges(charges, sum)
  num_charges = sum < 10 ? 1 : (sum < 100 ? 2 : (sum < 300 ? 3 : sum < 1000 ? 4 : 5))
  charges.sort_by{|c| -c.amount}.last(num_charges).reverse.map do |charge|
    {
      amount: -charge.amount,
      description: charge.description ? charge.description : charge.vendor.name }
  end
end

def charges_for_month(month, year: Time.now.year)
  @db.charges.all.select do |charge|
    charge.posted_date.to_date >= Date.new(year, month, 1) && charge.posted_date.to_date < Date.new(year, month, -1)
  end
end

def charges_by_tag_groups(charges, tag_groups)
  ctg = {}
  charges.each do |charge|
    tag_groups.each do |tags|
      if tags & charge.tags.map(&:name) == tags
        ctg[tags] ||= []
        ctg[tags] << charge
      end
    end
  end

  ctg
end