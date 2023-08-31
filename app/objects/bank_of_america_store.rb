require 'csv'

class Obj::BankOfAmericaStore < Obj::Store
  def initialize(db, directory)
    super()
    @db = db
    @directory = directory
  end

  def sync
    Dir["#{@directory}/*"].each do|fn|
      m = /CC_(\w+)(\d+)_(\d+)/.match(fn)
      next unless m

      last_four_digits = m[3]

      lines = CSV.readlines(fn, headers: true)
      charges = lines.map do |row|
        remote_id = row['Reference Number']
        next if remote_id.nil?

        date = row['Posted Date']
        vendor_name = row['Payee']
        vendor_address = row['Address']
        amount = row['Amount'].to_f
        charge = Obj::Charge.new(remote_id, amount)
        charge.vendor = Obj::Vendor.new(vendor_name, vendor_address)
        charge.credit_card = Obj::CreditCard.new(last_four_digits)
        charge
      end.reject(&:nil?)

      create_charges(charges, status_proc: status_proc)
    end
  end

  def create_charges(charges, update_charge: false, status_proc: ->(str){})
    charges.each do |charge|
      db_charge = find_or_add_charge(charge)
      db_vendor = find_or_add_vendor(charge.vendor) if charge.vendor
      db_credit_card = find_or_add_credit_card(charge.credit_card) if charge.credit_card

      db_charge.vendor = db_vendor
      db_charge.credit_card = db_credit_card
    end
  end

  def find_or_add_charge(charge)
    db_charge = @db.find_by(:charge, { remote_id: charge.remote_id} )
    return db_charge if db_charge

    @db.add_obj(charge.dup)
  end

  def find_or_add_vendor(vendor)
    db_vendor = @db.find_by(:vendor, { name: vendor.name} )
    return db_vendor if db_vendor

    @db.add_obj(vendor.dup)
  end

  def find_or_add_credit_card(credit_card)
    db_credit_card = @db.find_by(:credit_card, { last_four_digits: credit_card.last_four_digits} )
    return db_credit_card if db_credit_card

    @db.add_obj(credit_card.dup)
  end
end


