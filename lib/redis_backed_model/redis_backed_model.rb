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
      redis_commands << redis_set_command
      instance_variables.each do | var |
        redis_commands << instance_variable_to_redis(var) if instance_variable_to_redis(var)
      end
      scores.each do |score|
        redis_commands << score.to_redis
      end
      redis_commands
    end
    
    private
    
      attr_reader :id, :scores
    
      def add_to_instance_variables(key, value)
        if key.match(/score_\[\w+\|\w+\]/)
          add_to_scores(key, value)
        else
          self.instance_variable_set("@#{key}", value) 
        end
      end
    
      def add_to_scores(key, value)
        @scores ||= []
        @scores << SortedSet.new(self.class, id, Hash[key,value])
      end
      
      def instance_variable_to_redis(instance_variable)
        "hset #{model_name_for_redis}:#{id} #{instance_variable.to_s[1..-1]} #{instance_variable_get(instance_variable.to_s)}" unless instance_variable.to_s == '@id'
      end
        
      def model_name_for_redis
        class_as_string = self.class.to_s.demodulize.underscore        
      end
        
      def redis_set_command
        "sadd #{model_name_for_redis}_ids #{id}"
      end
      
  end
    
end
