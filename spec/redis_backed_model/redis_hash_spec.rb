require "spec_helper"

describe RedisBackedModel::RedisHash do
  
  describe ".matches?" do
    
    context "when attribute key only contains word characters" do
      let(:attribute) { {"abdcefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ_1234567890" => "some_value"} }
      it "returns true" do
        RedisBackedModel::RedisHash.matches?(attribute).should eq(true)
      end
    end
    
    context "when attribute key contains non-word characters" do
      it "returns false" do
        ['[', ']', '|'].each do |key|
          attribute = Hash[key + '_abc', 'some_value']
          RedisBackedModel::RedisHash.matches?(attribute).should eq(false), key
        end
      end
    end
    
    context "when value is nil" do
      let(:attribute) { Hash['some_key', nil] }      
      it "returns false" do
        RedisBackedModel::RedisHash.matches?(attribute).should eq(false)
      end
    end
    
  end

  describe "#attr_able" do
    let(:redis_hash) { RedisBackedModel::RedisHash.new(Object.new, Hash.new)}
    it "returns true" do
      redis_hash.attr_able?.should eq(true)
    end
  end
  
  describe "#to_attr_name" do
    let(:definition_attrs) { Hash['some_key', 'some_value'] }
    let(:attr_name) { RedisBackedModel::RedisHash.new(Object.new, definition_attrs).to_attr_name }
    
    it "is the attribute key converted to a symbol" do
      attr_name.should eq(definition_attrs.keys.first.to_sym)
    end   
  end

  
  describe "#to_instance_variable_name (converted to a string)" do
    let(:definition_attrs) { Hash['some_key', 'some_value'] }
    # let(:redis_backed_model) { OpenStruct.new(id:1) }
    let(:redis_backed_model) { double('redis_backed_model')}
    let(:instance_variable_name) { RedisBackedModel::RedisHash.new(redis_backed_model, definition_attrs).to_instance_variable_name}
    
    it "is the same as the attribute key" do
      instance_variable_name.should eq(definition_attrs.keys.first.instance_variableize)
    end   
  end
  
  describe "#to_instance_variable_value" do
    let(:definition_attrs) { Hash['some_key', 'some_value'] }
    let(:redis_backed_model) { double('redis_backed_model')}
    let(:instance_variable_value) { RedisBackedModel::RedisHash.new(redis_backed_model, definition_attrs).to_instance_variable_value }
    
    it "returns the attribute value" do
      instance_variable_value.should eq(definition_attrs.values.first)
    end
  end
    
  describe "#to_redis" do
    let(:definition_attrs) { Hash['some_key', 'some_value'] }
    # let(:redis_backed_model) { RedisBackedModel::RedisBackedModel.new(id:1) }
    let(:model) { double('redis_backed_model') }
    let(:redis_name) { 'my_model'}
    let(:id) { 1 }
    let(:redis_hash) { RedisBackedModel::RedisHash.new(model, definition_attrs) }
    
    it "has 4 parts seperated by '|'" do
      model.should_receive(:model_name_for_redis).and_return(redis_name)
      model.should_receive(:id).and_return(id)
      redis_hash.to_redis.split('|').count.should eq(4)
    end
    
    it "begins with hset" do
      model.should_receive(:model_name_for_redis).and_return(redis_name)
      model.should_receive(:id).and_return(id)
      redis_hash.to_redis.split('|')[0].should eq('hset')
    end
    
    it "has model_name_for_redis:model_id as hset key" do
      model.should_receive(:model_name_for_redis).and_return(redis_name)
      model.should_receive(:id).and_return(id)
      redis_hash.to_redis.split('|')[1].should eq("#{redis_name}:#{id}")
    end
    
    it "has attribute key as hset field" do
      model.should_receive(:model_name_for_redis).and_return(redis_name)
      model.should_receive(:id).and_return(id)
      redis_hash.to_redis.split('|')[2].should eq("#{definition_attrs.keys.first}")
    end
    
    it "has attribute value as hset value" do
      model.should_receive(:model_name_for_redis).and_return(redis_name)
      model.should_receive(:id).and_return(id)
      redis_hash.to_redis.split('|')[3].should eq("#{definition_attrs.values.first}")
    end
    
    context "when attribute key is a symbol" do
      let(:symbol_attrs) { Hash[:some_key, 'some_value']}
      let(:model) { double('redis_backed_model') }
      let(:redis_name) { 'my_model'}
      let(:id) { 1 }
      let(:redis_hash) { RedisBackedModel::RedisHash.new(model, definition_attrs) }      
      it "converts symbol to a string for hset field" do
        model.should_receive(:model_name_for_redis).and_return(redis_name)
        model.should_receive(:id).and_return(id)
        # redis_hash.to_redis.split('|')[2].should eq("#{definition_attrs.keys.first.to_s}")
        redis_hash.to_redis.split('|')[2].should eq("some_key")        
      end
    end
  end
  
end