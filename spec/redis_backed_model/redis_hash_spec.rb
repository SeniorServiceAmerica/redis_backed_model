require "spec_helper"

describe RedisBackedModel::RedisHash do
  
  describe ".matches?" do
    
    context "when attribute key only contains word characters" do
      let(:attribute) { {"abdcefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ_1234567890" => "some_value"} }
      it "returns true" do
        RedisBackedModel::RedisHash.matches?(attribute.keys.first).should eq(true)
      end
    end
    
    context "when attribute key contains non-word characters" do
      it "returns false" do
        ['[', ']', '|'].each do |key|
          attribute = Hash[key + '_abc', 'some_value']
          RedisBackedModel::RedisHash.matches?(attribute.keys.first).should eq(false), key
        end
      end
    end
    
  end
  
  describe "#to_instance_variable_name (converted to a string)" do
    let(:definition_attrs) { Hash['some_key', 'some_value'] }
    let(:redis_backed_model) { OpenStruct.new(id:1) }
    let(:instance_variable_name) { RedisBackedModel::RedisHash.new(redis_backed_model, definition_attrs).to_instance_variable_name}
    
    it "is the same as the attribute key" do
      instance_variable_name.to_s.deinstance_variableize.should eq(definition_attrs.keys.first)
    end
        
  end
  
  describe "#to_redis" do
    let(:definition_attrs) { Hash['some_key', 'some_value'] }
    let(:redis_backed_model) { RedisBackedModel::RedisBackedModel.new(id:1) }
    let(:to_redis) { RedisBackedModel::RedisHash.new(redis_backed_model, definition_attrs).to_redis }
    
    it "has 4 parts seperated by '|'" do
      to_redis.split('|').count.should eq(4)
    end
    
    it "begins with hset" do
      to_redis.split('|')[0].should eq('hset')
    end
    
    it "has model_name_for_redis:model_id as hset key" do
      to_redis.split('|')[1].should eq("#{redis_backed_model.model_name_for_redis}:#{redis_backed_model.id}")
    end
    
    it "has attribute key as hset field" do
      to_redis.split('|')[2].should eq("#{definition_attrs.keys.first}")
    end
    
    it "has attribute value as hset value" do
      to_redis.split('|')[3].should eq("#{definition_attrs.values.first}")
    end
    
  end
  
  
end