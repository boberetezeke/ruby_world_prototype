class Obj::Contact < Obj
  def initialize(name, phone, email)
    super(:contact, {name: name, phone: phone, email: email})
  end
end

