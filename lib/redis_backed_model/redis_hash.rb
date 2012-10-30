module RedisBackedModel
  class RedisHash
    
    def self.matches?(key)
      !key.match(/\W/) 
    end
    
    def initialize(object, definition)
      self.model        = object.class
      self.model_id     = object.id
      self.definition   = definition
      self      
    end

    def to_instance_variable_name
      redis_hash_field.instance_variableize
    end

    def to_redis
      "hset|#{redis_hash_key}|#{redis_hash_field}|#{redis_hash_value}"
    end

    private 
    
      attr_accessor :model, :model_id, :definition

      def redis_hash_field
        definition.keys.first.to_s
      end
      
      def redis_hash_key
        "#{model.model_name_for_redis}:#{model_id}"
      end

      def redis_hash_value
        definition.values.first
      end

  end
end