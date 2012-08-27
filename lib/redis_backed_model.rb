require "redis_backed_model/version"
require 'active_support/inflector'
require 'redis_backed_model/redis_backed_model'
require 'redis_backed_model/sorted_set'


# module RedisBackedModel
#   # Your code goes here...
#   class RedisBackedModel
#   
#     include SortedSet
#     
#     def initialize(attributes={})
#       if attributes.class == Hash
#         attributes.each do |key, value|
#           add_to_instance_variables(key, value)
#         end
#       else
#         raise ArgumentError
#       end
#     end
#     
#     private
#     
#       def add_to_instance_variables(key, value)
#         if key.match(/score_[\w+|\w+]/)
#           add_to_scores(key, value)
#         else
#           self.instance_variable_set("@#{key}", value) 
#         end
#       end
#     
#       def add_to_scores(key, value)
#         @scores ||= []
#         @scores << Hash[key, value]
#       end
#     
#   end
#     
# end
