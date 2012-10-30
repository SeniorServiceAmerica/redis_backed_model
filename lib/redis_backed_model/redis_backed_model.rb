module RedisBackedModel
  class RedisBackedModel

    attr_reader :id

    # Checks to see if the redis store has the resource. Returns true if found, false if not 
    def self.exists?(id)
      id && find(id) != []
    end

    # Finds and returns one or more objects by their id.
    # Pass in a single id or an array of ids.
    #   obj.find(1) => obj
    #   obj.find([1,2,3]) => [obj,obj,obj]
    # returns an empty array if no object matches the id in Redis
    #   obj.find(bad_id) => []
    def self.find(*args)
      found = []
      args.flatten.each do |id|
        attributes = $redis.hgetall(instance_redis_hash_key(id))
        found << self.new(attributes.merge({'id' => id})) if attributes.size > 0
      end
      (found.count == 1) ? found.first : found
    end

    def self.model_name_for_redis
      self.name.demodulize.underscore
    end

    # Instantiates the object with the provided attributes.
    # If the object does not have an instance variable that matches one of the passed attributes, one will be created.
    def initialize(attributes={})
      if attributes.class == Hash
        attributes.each do |key, value|
          add_instance_variable(key, value)
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
      self.class.model_name_for_redis
    end
    
    private
    
      def self.data_structures
        [
          RedisHash,
          RedisSet,
          SortedSet
        ]
      end

      def self.instance_redis_hash_key(id)
        "#{model_name_for_redis}:#{id}"
      end
        
      def add_data_structure(data_structure)
        self.instance_variable_set(data_structure.to_instance_variable_name, data_structure)
      end
        
      def add_instance_variable(key, value)
        if (matched_data_structures = matching_data_structure(key))
          matched_data_structures.each do |match|
            add_data_structure(match.new(self, Hash[key, value]))
          end
        else
          self.instance_variable_set("@#{key}", value) 
        end        
      end

      def matching_data_structure(key)
        self.class.data_structures.select{ |data_type| data_type.matches?(key) }
      end

      # def add_to_instance_variables(key, value)
      #   if is_a_sorted_set?(key)
      #     sorted_set_instance_variable(key,value)
      #   else
      #     self.instance_variable_set("@#{key}", value) 
      #   end
      # end
          
      # def is_a_sorted_set?(key)
      #   SortedSet.matches?(key)
      # end
      #       
      # def sorted_set_instance_variable(key, value)
      #   SortedSet.new(self, Hash[key,value]).add_to(self)
      # end
        
  end
    
end
