module RedisBackedModel
  class Commands < Array
    # def initialize(obj)
    #   @obj = obj
    #   # self << id_set_command
    # 
    #   @obj.instance_variables.each do | var |
    #     build_command_for_variable(var)
    #   end
    #   
    #   self
    # end

    def to_instance_variables
      
    end
    
    def to_redis
      self.map { |data_structure| data_structure.to_redis }
    end
    
    private
    
    # def id_set_command
    #   "sadd|#{@obj.redis_name}_ids|#{@obj.id}"
    # end 

    # def build_command_for_variable(variable)
    #   value = @obj.instance_variable_get(variable)
    #   if value.respond_to?(:to_redis)
    #     self << value.to_redis
    #   elsif value
    #     self << instance_variable_to_redis(variable,value)
    #   end
    # end
    # 
    # def instance_variable_to_redis(instance_variable,value)
    #   "hset|#{@obj.redis_name}:#{@obj.id}|#{instance_variable.to_s.deinstance_variableize}|#{value}"
    # end  
  end
end