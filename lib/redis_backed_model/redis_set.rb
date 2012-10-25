module RedisBackedModel
  class RedisSet

    def self.matches?(key)
      key.to_s == 'id'
    end

    def initialize(object, definition)
      self.model        = object.class
      self.model_id     = object.id
      self.definition   = definition
      self
    end

    def to_instance_variable_name
      "set_#{key_name}".instance_variableize
    end
    
    def to_redis
      "sadd|#{key}|#{member}"
    end

    private 
    
      attr_accessor :model, :model_id, :definition

      def key
        "#{model.model_name_for_redis}_#{key_name}"
      end
      
      def key_name
        definition.keys.first.to_s.pluralize
      end
            
      def member
        definition.values.first        
      end

  end
end