class Obj::Call < Obj
  def initialize(contact, length)
    super(:call, {contact: contact, length: length})
  end
end

