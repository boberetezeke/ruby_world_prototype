class Obj::Change < Obj
  def initialize(sym, old_value, new_value)
    super(:change, {sym: sym, change_type: :simple, old_value: old_value, new_value: new_value}, track_changes: false)
  end
end