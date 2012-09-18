module RedisBackedModel
  class RedisBackedModel

    attr_reader :id

    # Finds and returns one or more objects by their id.
    # Pass in a single id or an array of ids.
    #   obj.find(1) => obj
    #   obj.find([1,2,3]) => [obj,obj,obj]
    # returns an empty array if no object matches the id in Redis
    #   obj.find(bad_id) => []
    def self.find(*args)
      found = []
      args.flatten.each do |id|
        attributes = $redis.hgetall("#{self.to_s.underscore}:#{id}")
        found << self.new(attributes.merge({'id' => id})) if attributes.size > 0
      end
      (found.count == 1) ? found.first : found
    end

    # Instantiates the object with the provided attributes.
    # If the object does not have an instance variable that matches one of the passed attributes, one will be created.
    def initialize(attributes={})
      if attributes.class == Hash
        attributes.each do |key, value|
          add_to_instance_variables(key, value)
        end
      else
        raise ArgumentError
      end
    end
    
    # Serializes the object as redis commands.
    def to_redis
      Commands.new(self)
    end

    def model_name_for_redis
      class_as_string = self.class.to_s.demodulize.underscore        
    end
    
    private
    
    
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
      
      def scores
        @scores ||= []
      end
  end
    
end
