module RedisBackedModel
  class Commands < Array
    def initialize(obj)
      @obj = obj
      self << id_set_command

      @obj.instance_variables.each do | var |
        build_command_for_variable(var)
      end
      
      self
    end
    
    private
    
    def id_set_command
      "sadd|#{@obj.model_name_for_redis}_ids|#{@obj.id}"
    end 

    def build_command_for_variable(variable)
      value = @obj.instance_variable_get(variable)
      if value.respond_to?(:each)
        value.each do |redis_object|
          self << redis_object.to_redis
        end
      elsif value
        self << instance_variable_to_redis(variable,value)
      end
    end

    def instance_variable_to_redis(instance_variable,value)
      "hset|#{@obj.model_name_for_redis}:#{@obj.id}|#{instance_variable.to_s.deinstance_variableize}|#{value}"
    end  
  end
end