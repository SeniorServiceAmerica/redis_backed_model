require "spec_helper"
require "ostruct"

describe RedisBackedModel::RedisSet do
  
  describe ".matches?" do
    it "returns true when key is string 'id'" do
      RedisBackedModel::RedisSet.matches?({'id' => 'some_value'}).should eq(true)
    end
    
    it "returns true when key is symbol :id" do
      RedisBackedModel::RedisSet.matches?({:id => 'some_value'}).should eq(true)      
    end
    
    it "returns false when value is nil" do
      RedisBackedModel::RedisSet.matches?({'id' => nil }).should eq(false)      
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
    # let(:redis_backed_model) { RedisBackedModel::RedisBackedModel.new(id:1) }
    # let(:model) { OpenStruct.new(id: 1, model_name_for_redis: 'open_struct')}
    let(:model) { double('redis_backed_model') }
    let(:redis_set) { RedisBackedModel::RedisSet.new(model, Hash['id', 1])}

    it "command is in 3 parts seperated by |" do
      model.should_receive(:model_name_for_redis).and_return('my_model')
      redis_set.to_redis.split('|').count.should eq(3)
    end
    
    it "starts with sadd" do
      model.should_receive(:model_name_for_redis).and_return('my_model')
      redis_set.to_redis.split('|')[0].should eq('sadd')
    end
    
    it "has redisified model_name + _ + pluralized definition key name as redis key" do
      model.should_receive(:model_name_for_redis).and_return('my_model')
      redis_set.to_redis.split('|')[1].should eq("my_model_#{definition_attrs.keys.first.pluralize}")      
    end
    
    it "has the definition value for the redis member" do
      model.should_receive(:model_name_for_redis).and_return('my_model')
      redis_set.to_redis.split('|')[2].should eq("#{definition_attrs.values.first}")
    end
    
  end
  
end