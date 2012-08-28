module ActiveSupport::Inflector

  def deinstance_variableize(the_string)
    result = the_string.to_s.dup
    result.downcase.gsub(/^@/, '')
  end
  
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
