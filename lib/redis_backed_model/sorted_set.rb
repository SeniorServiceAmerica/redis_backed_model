module RedisBackedModel

  class SortedSet
  require 'date'
    
  
    def initialize(model, model_id, definition)
      @model      = model
      @model_id   = model_id
      @definition = definition
    end
  
    def to_redis
      "zadd #{key} #{score} #{member}"
    end
  
    private
      
      attr_accessor :model, :model_id #, :by_attribute, :score_label, :score
      
      def definition_keys
        @definition.keys.first
      end
      
      def definition_values
        @definition.values.first
      end
      
      def key_by
        parse_definition(definition_keys)[1]
      end
      
      def key_for
        parse_definition(definition_keys)[0]        
      end

      def key_model_name
        @model.to_s.underscore.pluralize
      end

      def key_for_value
        parse_definition(definition_values)[0]
      end

      def member
        @model_id
      end
        
      def key
        "#{key_model_name}_for_#{key_for}_by_#{key_by}:#{key_for_value}"
      end

      def score
        score = parse_definition(definition_values)[1]
        key_by == 'date' ? Date.parse(score).to_time.to_f : score
      end
      
      def parse_definition(string)
        string.match(/.*\[(\S+)\]/)[1].split('|')
      end
  
  end

end