module RedisBackedModel
  class RedisBackedModel

    def initialize(attributes={})
      if attributes.class == Hash
        attributes.each do |key, value|
          add_to_instance_variables(key, value)
        end
      else
        raise ArgumentError
      end
    end
    
    def to_redis
      redis_commands = []
      redis_commands << id_set_command
      instance_variables.each do | var |
        build_command_for_variable(var, redis_commands)
      end

      redis_commands
    end
    
    private
    
      attr_reader :id
    
      def add_to_instance_variables(key, value)
        if key.match(/score_\[\w+\|\w+\]/)
          add_to_scores(key, value)
        else
          self.instance_variable_set("@#{key}", value) 
        end
      end
    
      def add_to_scores(key, value)
        scores << SortedSet.new(self.class, id, Hash[key,value])
      end
      
      def build_command_for_variable(variable, collection)
        value = instance_variable_get(variable)
        if value.respond_to?(:each)
          value.each do |redis_object|
            collection << redis_object.to_redis
          end
        else
          collection << instance_variable_to_redis(variable)
        end
      end

      def id_set_command
        "sadd|#{model_name_for_redis}_ids|#{id}"
      end
      
      def instance_variable_to_redis(instance_variable)
        "hset|#{model_name_for_redis}:#{id}|#{instance_variable.to_s.deinstance_variableize}|#{instance_variable_get(instance_variable.to_s)}"
      end
        
      def model_name_for_redis
        class_as_string = self.class.to_s.demodulize.underscore        
      end

      def scores
        @scores ||= []
      end
  end
    
end
