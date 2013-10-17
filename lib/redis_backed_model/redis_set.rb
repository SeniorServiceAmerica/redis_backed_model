module RedisBackedModel
  class RedisSet

    def self.matches?(attribute_hash)
      attribute_hash.keys.first.to_s == 'id' && !attribute_hash.values.first.nil?
    end

    def initialize(model, definition)
      self.model        = model
      self.definition   = definition
      self
    end

    def attr_able?
      false
    end

    def to_instance_variable_name
      "set_#{key_name}".instance_variableize
    end

    def to_redis
      "sadd|#{key}|#{member}"
    end

    private 
    
      attr_accessor :model, :definition

      def key
        "#{model.redis_name}_#{key_name}"
      end
      
      def key_name
        definition.keys.first.to_s.pluralize
      end
            
      def member
        definition.values.first        
      end

  end
end