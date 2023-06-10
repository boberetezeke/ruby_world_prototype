class Obj
  attr_reader :id, :type_sym, :attrs
  def initialize(type_sym, attrs)
    @tags = []
    @type_sym = type_sym
    @attrs = attrs
    @id =  SecureRandom.hex
  end

  def update(obj)
    @attrs = obj.attrs
  end

  def method_missing(sym, *args)
    if @attrs.keys.include?(sym)
      @attrs[sym]
    else
      super
    end
  end

  def add_tag(tag)
    @tags.push(tag) unless @tags.include(tag)
  end
end
