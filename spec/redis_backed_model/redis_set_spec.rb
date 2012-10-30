require "spec_helper"
require "ostruct"

describe RedisBackedModel::RedisSet do
  
  describe ".matches?" do
    it "returns true when key is string 'id'" do
      RedisBackedModel::RedisSet.matches?('id').should eq(true)
    end
    
    it "returns true when key is symbol :id" do
      RedisBackedModel::RedisSet.matches?(:id).should eq(true)      
    end
  end
  
  describe "#to_instance_variable_name" do
    let(:definition_attrs) { Hash['id', 1] }
    let(:redis_backed_model) { OpenStruct.new(id:1) }
    let(:instance_variable_name_string) { RedisBackedModel::RedisSet.new(redis_backed_model, definition_attrs).to_instance_variable_name.to_s.deinstance_variableize}
    
    it "begins with 'set'" do
      instance_variable_name_string.split('_')[0].to_s.should eq('set')
    end
    
    it "ends with the key as string" do
      instance_variable_name_string.split('_')[1].to_s.should eq('ids')      
    end
    
    it "has no other parts" do
      instance_variable_name_string.split('_').count.should eq(2)      
    end
  end
  
  describe "#to_redis" do
    let(:definition_attrs) { Hash['id', 1] }
    let(:redis_backed_model) { RedisBackedModel::RedisBackedModel.new(id:1) }
    let(:redis_set) { RedisBackedModel::RedisSet.new(redis_backed_model, Hash['id', 1])}

    it "command parts are seperated by |" do
      redis_set.to_redis.scan('|').count.should > 0
    end
    
    it "starts with sadd" do
      redis_set.to_redis.split('|')[0].should eq('sadd')
    end
    
    it "has redisified model_name + pluralized definition key name as redis key" do
      redis_set.to_redis.split('|')[1].should eq("#{redis_backed_model.model_name_for_redis}_#{definition_attrs.keys.first.pluralize}")      
    end
    
    it "has the definition value for the redis member" do
      redis_set.to_redis.split('|')[2].should eq("#{definition_attrs.values.first}")
    end
    
  end
  
end