require 'csv'

class Obj::BankOfAmericaStore < Obj::Store
  def initialize(db, directory)
    super()
    @db = db
    @directory = directory
  end

  def sync
    puts "directory: #{@directory}"
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

      create_tags
      create_charges(charges, status_proc: status_proc)
    end
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
      tag_charge(db_charge)
    end
  end

  def charge_rules
    @charge_rules ||= charge_rules_base.map do |charge_rule|
      Financial::ChargeRule.new(
        @db,
        charge_rule[0],
        ->(charge) {
          m = charge_rule[1].match(charge.vendor.name.gsub(/'/, ''))
          charge_rule[2] ? m && charge.amount == charge_rule[2] : m
        }
      )
    end
  end

  def charge_rules_base
    [
      [['auto', 'gas'],               /aarons grocery/i],
      [['auto', 'gas'],               /caseys/i],
      [['auto', 'gas'],               /cenex/i],
      [['auto', 'gas'],               /e&g/i],
      [['auto', 'gas'],               /elk river gas/i],
      [['auto', 'gas'],               /holiday/i],
      [['auto', 'gas'],               /simonson/i],
      [['auto', 'gas'],               /moreys markets/i],
      [['auto', 'parking'],           /fnp parking/i],
      [['auto', 'parking'],           /united.*childrens/i],
      [['clothing'],                  /talbots/i],
      [['entertainment'],             /admiral ds/i],
      [['entertainment'],             /alma/i],
      [['entertainment'],             /cafe latte/i],
      [['entertainment'],             /city of st paul como dona/i],
      [['entertainment'],             /coconut/i],
      [['entertainment'],             /connys/i],
      [['entertainment'],             /cork & cask/i],
      [['entertainment'],             /finnish/i],
      [['entertainment'],             /good life/i],
      [['entertainment'],             /hen house/i],
      [['entertainment'],             /holiday inn/i],
      [['entertainment'],             /johns pizza/i],
      [['entertainment'],             /marc heu/i],
      [['entertainment'],             /nouvelle brewing/i],
      [['entertainment'],             /shaughnessy/i],
      [['entertainment'],             /pizza luce/i],
      [['entertainment'],             /pizzeria lola/i],
      [['entertainment'],             /st paul brewing/i],
      [['entertainment'],             /swede hollow/i],
      [['entertainment'],             /taco libre/i],
      [['entertainment'],             /the mill/i],
      [['entertainment'],             /tommy chicagos pizza/i],
      [['exercise'],                  /ymca/i],
      [['gifts'],                     /accentric & european/i], # Depot - St Cloud
      [['grocery'],                   /brents fresh foods red lake fall/i],
      [['grocery'],                   /cub foods/i],
      [['grocery'],                   /farmers store/i],
      [['grocery'],                   /kowalski/i],
      [['grocery'],                   /mississippi market/i],
      [['grocery'],                   /toasted/i],
      [['home', 'expenses'],          /ace hardware/i],
      [['home', 'expenses'],          /apple store/i],
      [['home', 'expenses'],          /frattallones/i],
      [['home', 'expenses'],          /home depot/i],
      [['home', 'expenses'],          /menards/i],
      [['home', 'expenses'],          /michaels/i],
      [['home', 'expenses'],          /office depot/i],
      [['home', 'expenses'],          /target/i],
      [['home', 'expenses'],          /walgreens/i],
      [['home', 'expenses'],          /who gives a crap/i],
      [['home', 'expenses', 'yard'],  /mother earth gardens/i],
      [['home', 'expenses', 'yard'],  /urbans farm & greenh/i],
      [['misc'],                      /foreign transaction fee/i],
      [['news'],                      /compact magazine/i],
      [['news'],                      /dissenter/i],
      [['news'],                      /feedbin/i],
      [['news'],                      /first look media/i],
      [['news'],                      /freddiedeboer/i],
      [['news'],                      /future crunch/i],
      [['news'],                      /kelton/i],
      [['news'],                      /krystal and saagar/i],
      [['news'],                      /lever/i],
      [['news'],                      /mental hellth/i],
      [['news'],                      /mondoweiss/i],
      [['news'],                      /nation/i],
      [['news'],                      /pioneer press/i],
      [['news'],                      /recombobulation area/i],
      [['news'],                      /tyt/i],
      [['news'],                      /unicorn riot/i],
      [['news'],                      /yasha levine/i],
      [['payment'],                   /ba electronic payment/i],
      [['phone'],                     /tmobile/i],
      [['politics', 'donation'],      /350.org/i],
      [['politics', 'donation'],      /mn350/i],
      [['politics', 'donation'],      /democratic socialists/i],
      [['politics', 'donation'],      /doctors w\/o border/i],
      [['politics', 'donation'],      /greenpeace/i],
      [['politics', 'donation'],      /nelsieyang/i],
      [['politics', 'donation'],      /matriarch/i],
      [['politics', 'donation'],      /peta/i],
      [['politics', 'donation'],      /progressive internat/i],
      [['politics', 'donation'],      /rocket dollar/i],
      [['services', 'computer'],      /amazon web services/i],
      [['services', 'computer'],      /dreamhost/i],
      [['services', 'computer'],      /dropbox/i],
      [['services', 'computer'],      /evernote/i],
      [['services', 'computer'],      /heroku/i],
      [['services', 'computer'],      /jetbrains/i],
      [['services', 'computer'],      /twilio/i],
      [['services', 'computer'],      /zoom/i],
      [['services', 'home', 'internet'],   /quantum fiber/i],
      [['services', 'home', 'security'],   /adt/i],
      [['steve', 'expenses'],         /abogados/i],
      [['steve', 'expenses'],         /cafe ceres/i],
      [['steve', 'expenses'],         /claddagh/i],
      [['steve', 'expenses'],         /dogwood/i],
      [['steve', 'expenses'],         /emery/i],  # Spyhouse downtown
      [['steve', 'expenses'],         /groundswell/i],
      [['steve', 'expenses'],         /kindle/i],
      [['steve', 'expenses'],         /bully brew/i],
      [['steve', 'expenses'],         /rock creek coffee/i],
      [['transportation'],            /metrotrans/i],
      [['transportation'],            /hourcar/i],
      [['travel'],                    /allianz/i],
      [['travel'],                    /airbnb/i],
      [['travel'],                    /americinn/i],
      [['tv'],                        /prime/i],
      [['tv'],                        /apple\.com/i, -0.99],
      [['tv'],                        /apple\.com/i, -2.99],
      [['tv'],                        /apple\.com/i, -4.30],
      [['tv'],                        /apple\.com/i, -5.39],
      [['tv'],                        /apple\.com/i, -6.45],
      [['tv'],                        /apple\.com/i, -6.46],
      [['tv'],                        /apple\.com/i, -7.54],
      [['tv'],                        /apple\.com/i, -8.60],
      [['tv'],                        /apple\.com/i, -10.75],
      [['tv'],                        /apple\.com/i, -12.90],
      [['tv'],                        /apple\.com/i, -22.64],
      [['tv'],                        /apple\.com/i, -26.97],
      [['tv'],                        /apple\.com/i, -31.27],
      [['tv'],                        /britbox/i],
      [['tv'],                        /hulu/i],
      [['tv'],                        /netflix/i],
      [['tv'],                        /peacock/i],
      [['tv'],                        /pbs/i],
      [['tv'],                        /spotify/i],
    ]
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


