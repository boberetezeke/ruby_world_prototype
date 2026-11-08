def recent_charges
  # Fetch recent charges from the database or an external API
  charges = @db.charges.all.select { |charge| charge.amount < 0 }.sort_by(&:posted_date).reverse.first(10)

  # Format the charges for display
  formatted_charges = charges.map do |charge|
    {
      vendor: charge.vendor.name,
      amount: charge.amount,
      created_at: charge.posted_date.strftime("%Y-%m-%d"),
      tags: charge.tags.map(&:name).join(':')
    }
  end

  # Return the formatted charges
  formatted_charges
end