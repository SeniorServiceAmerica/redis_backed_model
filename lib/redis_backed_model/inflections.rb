module ActiveSupport::Inflector

  # Downcases and removes a leading @
  def deinstance_variableize(the_string)
    result = the_string.to_s.dup
    result.downcase.gsub(/^@/, '')
  end
  
  # Adds a @ to the beginning of <tt>the_string</tt> and returns it as a symbol
  def instance_variableize(the_string)
    "@#{the_string}".to_sym
  end
end

class String
  def deinstance_variableize
    ActiveSupport::Inflector.deinstance_variableize(self)
  end
  
  def instance_variableize
    ActiveSupport::Inflector.instance_variableize(self)
  end
  
end
