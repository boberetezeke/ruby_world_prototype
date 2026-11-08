def unclassified_charges
  @db.charges.all.select { |charge| charge.tags.empty? && charge.amount < 0 }.map do |charge|
    {
      remote_id: charge.remote_id,
      vendor: charge.vendor.name,
      amount: charge.amount,
      date: charge.posted_date.strftime('%Y-%m-%d'),
    }
  end
end