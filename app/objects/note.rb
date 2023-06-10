class Obj::Note < Obj
  def initialize(text)
    super(:note, {text: text})
  end
end

