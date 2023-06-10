class Obj::Email < Obj
  def initialize(contacts, subject, body)
    super(:email, {contacts: contacts, subject: subject, body: body, state: :draft})
  end

  def send_email
    @state = :sent
  end
end

