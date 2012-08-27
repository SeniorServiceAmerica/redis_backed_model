module RedisBackedModel

  class SortedSet
  require 'date'
    
  
    def initialize(model, model_id, score)
      @model      = model
      @model_id   = model_id
      @score      = score
    end
  
    def to_redis
      "#{sorted_set_key} #{sorted_set_score} #{member}"
    end
  
    private
      
      attr_accessor :model, :model_id, :by_attribute, :score_label, :score
                  
      def key_by
        @score.keys.first.match(/score_\[\S+\|(\S+)\]/)[1]        
      end
      
      def key_for
        @score.keys.first.match(/score_\[(\S+)\|/)[1]
      end

      def key_model_name
        @model.to_s.underscore.pluralize
      end

      def key_value
        @score.values.first.match(/\[(\S+)\|/)[1]
      end

      def member
        @model_id
      end
        
      def sorted_set_key
        "#{key_model_name}_for_#{key_for}_by_#{key_by}:#{key_value}"
      end

      def sorted_set_score
        score = @score.values.first.match(/\[\S+\|(\S+)\]/)[1]
        key_by == 'date' ? Date.parse(score).to_time.to_f : score
      end
  
  end

end