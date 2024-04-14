require 'csv'
require 'time'

class Obj::BankOfAmericaStore < Obj::Store
  def initialize(db, directory)
    super()
    @db = db
    @directory = directory
  end

  def sync
    # puts "directory: #{@directory}"
    Dir["#{@directory}/*"].each do|fn|
      m = /CC_(\w+)(\d+)_(\d+)/.match(fn)
      next unless m

      last_four_digits = m[3]

      lines = CSV.readlines(fn, headers: true)
      charges = lines.map do |row|
        remote_id = row['Reference Number']
        next if remote_id.nil?

        date = Time.strptime(row['Posted Date'], '%m/%d/%Y').to_date
        vendor_name = row['Payee']
        vendor_address = row['Address']
        amount = row['Amount'].to_f
        charge = Obj::Charge.new(remote_id, amount, date)
        charge.vendor = Obj::Vendor.new(vendor_name, vendor_address)
        charge.credit_card = Obj::CreditCard.new(last_four_digits)
        charge
      end.reject(&:nil?)

      create_tags
      create_charges(charges, status_proc: status_proc)
    end
  end

  def charge_rules_base
    Financial::BankOfAmericaChargeRules.rules
  end

  def create_tags
    charge_rules_base.each do |charge_rule_base|
      charge_rule_base[0].each do |tag_name|
        tag = @db.find_by(:tag, {name: tag_name})
        @db.add_obj(Obj::Tag.new(tag_name)) unless tag
      end
    end
  end

  def create_charges(charges, update_charge: false, status_proc: ->(str){})
    charges.each do |charge|
      db_charge = find_or_add_charge(charge)

      db_vendor = find_or_add_vendor(charge.vendor) if charge.vendor
      db_credit_card = find_or_add_credit_card(charge.credit_card) if charge.credit_card

      db_charge.vendor = db_vendor
      db_charge.credit_card = db_credit_card
      db_charge.update(charge)

      update_description(db_charge, db_vendor)
      tag_charge(db_charge)
    end
  end

  def charge_rules
    @charge_rules ||= charge_rules_base.map do |charge_rule|
      tags = charge_rule[0]
      regex = charge_rule[1]
      options = charge_rule[2]
      description = options&.fetch(:description, nil)
      price_range = options&.fetch(:price_range, nil)
      Financial::ChargeRule.new(
        @db,
        tags,
        description,
        ->(charge) {
          m = regex.match(charge.vendor.name.gsub(/'/, ''))
          if price_range
            m && price_range.include?(charge.amount)
          else
            m
          end
        }
      )
    end
  end

  def update_description(charge, vendor)
    charge_rules.each do |charge_rule|
      if charge_rule.match?(charge)
        charge.description = charge_rule.description || vendor.name
      end
    end
  end

  def tag_charge(db_charge)
    charge_rules.each do |charge_rule|
      if charge_rule.match?(db_charge)
        tags_to_add = charge_rule.tags - db_charge.tags
        tags_to_remove = db_charge.tags - charge_rule.tags
        find_or_add_tags(tags_to_add, db_charge)
        remove_tags(tags_to_remove, db_charge)
      end
    end
  end

  def find_or_add_tags(tags, db_charge)
    tags.each do |tag|
      tagging = Obj::Tagging.new
      tagging.tag = tag
      tagging.taggable = db_charge
      @db.add_obj(tagging)
    end
  end

  def remove_tags(tags, db_charge)
    tags.each do |tag|
      tagging = @db.find_by(:tagging, {tag_id: tag.id, taggable_type: :charge, taggable_id: db_charge.id})
      @db.rem_obj(tagging)
      tagging.tag = nil
      tagging.taggable = nil
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


