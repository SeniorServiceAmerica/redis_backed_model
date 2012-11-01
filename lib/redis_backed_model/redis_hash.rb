module RedisBackedModel
  class RedisHash
    
    def self.matches?(attribute)
      (attribute.keys.first.match(/\W/) || attribute.values.first.nil?) ? false : true
    end
    
    def initialize(model, definition)
      self.model        = model
      self.definition   = definition
      self      
    end
    
    def attr_able?
      true
    end

    def to_attr_name
      redis_hash_field.to_sym
    end

    def to_instance_variable_name
      redis_hash_field.instance_variableize
    end

    def to_instance_variable_value
      redis_hash_value
    end

    def to_redis
      "hset|#{redis_hash_key}|#{redis_hash_field}|#{redis_hash_value}"
    end

    private 
    
      attr_accessor :model, :definition

      def redis_hash_field
        definition.keys.first.to_s
      end
      
      def redis_hash_key
        "#{model.model_name_for_redis}:#{model.id}"
      end

      def redis_hash_value
        definition.values.first
      end

  end
end