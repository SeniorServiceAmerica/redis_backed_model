require "spec_helper"

describe RedisBackedModel do
  before(:all) do
    class InheritingFromRedisBackedModel < RedisBackedModel::RedisBackedModel; end
  end
  
  before(:each) do
    @attributes_with_id = {}
    @size = rand(9) + 1
    key_seed = 'abcdefghijklmn'
    (1..@size).each do | i |
      key  = key_seed[i..(rand(i)+i)]
      @attributes_with_id[key] = i
    end
    @attributes_with_id['id'] = 1
  end
  
  describe "#initialize" do 

    context "given no arguments" do
      let(:rbm) {InheritingFromRedisBackedModel.new}

      it "has a @data instance variable" do 
        rbm.instance_variables.inspect.should eq('[:@data]')
      end
      
    end
    
    context "given a hash" do
      let(:attributes) {
          number_of_random_keys = rand(9) + 1
          attributes = {'id' => 1 }
          (1..number_of_random_keys).each do | i |
            random_key = 'abcdefghijklmn'[i..(rand(i)+i)]
            attributes[random_key] = i
          end
          attributes
        }
      it "checks all key-value pairs to see if they match any defined data structure" do
        attributes.each_pair do |k,v|
          RedisBackedModel::RedisBackedModel.redis_data_structures.each do |structure|
            structure.should_receive(:matches?).with(Hash[k,v])
          end
        end
        InheritingFromRedisBackedModel.new(attributes)
      end
      it "builds a new data structure if there is a match" do
        attribute = {'foo' => 'bar'}
        RedisBackedModel::RedisBackedModel.redis_data_structures.each do |structure|
          structure.stub(:matches?).and_return(true)
          structure.should_receive(:new).with(anything(), attribute) { OpenStruct.new(attr_able?: false) }
        end
        InheritingFromRedisBackedModel.new(attribute)
      end
      it "does not build a data structure if there is a no match" do
        attribute = {'foo' => 'bar'}
        RedisBackedModel::RedisBackedModel.redis_data_structures.each do |structure|
          structure.stub(:matches?).and_return(false)
          structure.should_not_receive(:new)
        end
        InheritingFromRedisBackedModel.new(attribute)
      end
      it "creates an instance variable if the data structure is attr_able" do
        attribute = {'foo' => 'bar'}
        matching = RedisBackedModel::RedisBackedModel.redis_data_structures.first
        matching.stub(:matched?).and_return(true)
        matching.stub(:new) { 
                              OpenStruct.new(attr_able?: true, 
                                              to_instance_variable_name: :@foo,
                                              to_instance_variable_value: 'bar', 
                                              to_attr_name: :foo) 
                                }
        RedisBackedModel::RedisBackedModel.redis_data_structures[1..-1].each { |structure| structure.stub(:matches?).and_return(false)}
        rbm = InheritingFromRedisBackedModel.new(attribute)
        rbm.instance_variables.count.should eq(2)
      end
      it "does not create an instance variable if the data structure is not attr_able" do
        attribute = {'foo' => 'bar'}
        matching = RedisBackedModel::RedisBackedModel.redis_data_structures.first
        matching.stub(:matched?).and_return(true)
        matching.stub(:new) { 
                              OpenStruct.new(attr_able?: false, 
                                              to_instance_variable_name: :@foo,
                                              to_instance_variable_value: 'bar', 
                                              to_attr_name: :foo) 
                                }
        RedisBackedModel::RedisBackedModel.redis_data_structures[1..-1].each { |structure| structure.stub(:matches?).and_return(false)}
        rbm = InheritingFromRedisBackedModel.new(attribute)
        rbm.instance_variables.count.should eq(1)
      end
    end

    it "raises an argument error if something other than a hash is passed in" do 
      expect { InheritingFromRedisBackedModel.new('w') }.to raise_error(ArgumentError)
      expect { InheritingFromRedisBackedModel.new(['w', 1]) }.to raise_error(ArgumentError)
    end

  end

  describe "to_redis" do 

    it "returns an enumerable object" do 
      rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
      rbm.to_redis.should respond_to(:each)
    end 

    it "returns a command to add the model id to a set named (model_name)_ids" do 
      rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
      rbm.to_redis.should include("sadd|#{rbm.class.to_s.underscore}_ids|1")    
    end

    context "given multiple (2) non-score instance variables" do
      before(:each) do 
        @attributes = {:id => 1, :foo=>20}
        @obj = InheritingFromRedisBackedModel.new(@attributes)
        @redis_commands = @obj.to_redis
        @hset_commands = @redis_commands.select { |command| command.match(/^hset\|/)}
      end

      it "returns two hset commands" do
        # pending("revisit once redis data structures in place")
        @hset_commands.count.should eq(2)
      end

      it "has hset commands with format 'hset|model_name:id|variable_name|variable|value'" do
        # pending("revisit once redis data structures in place")        
        @attributes.each do |variable_name,value|
          @hset_commands.should include("hset|#{@obj.redis_name}:#{@obj.id}|#{variable_name}|#{value}") 
        end
      end
      
    end

    context "given an instance variable value of nil" do
      before(:each) do 
        @attributes = {:id => 1, :foo=>nil}
        @obj = InheritingFromRedisBackedModel.new(@attributes)
        @redis_commands = @obj.to_redis
        @hset_commands = @redis_commands.select { |command| command.match(/^hset\|/)}        
      end

      it "ignores the nil variable when creating commands" do
        # pending("revisit once redis data structures in place")        
        @hset_commands.count.should == 1
        @hset_commands.each do |command| 
          command.should include("id")
        end
      end
    end
    
    context "given an instance variable value with spaces" do
      before(:each) do 
        @attributes = {:foo=>'value with spaces'}
        @obj = InheritingFromRedisBackedModel.new(@attributes)
        @redis_commands = @obj.to_redis
        @hset_commands = @redis_commands.select { |command| command.match(/^hset\|/)}        
      end

      it "creates a command for the instance variable" do
        @hset_commands[0].should include('value with spaces')
      end
    end

    context "given score_ instance variables" do
      before(:each) do
        @scores = ['score_[foo|bar]', 'score_[baz|qux]', 'score_[wibble|wobble]']
        @scores.each_with_index do |score,index|
          @attributes_with_id[score]  = "[#{index}|#{index + 1}]"
        end
        @rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
      end

      it "creates hset commands for each non-'score_' attribute" do
        # pending("revisit once redis data structures in place")
        expected = @attributes_with_id.keys.count - @scores.count
        @rbm.to_redis.select {|command| command.match(/hset/)}.count.should eq(expected)
      end

      it "creates sorted_set (zadd) commands for each score attribute" do 
        @rbm.to_redis.select { |command| command.match(/zadd/) }.count.should eq(@scores.count)
      end
    end

  end

  describe ".find" do 
    before(:each) do 
      $redis.hset('inheriting_from_redis_backed_model:0', 'foo', 'bar')
      $redis.hset('inheriting_from_redis_backed_model:1', 'wibble', 'wobble')
    end
    it "should return an array if objects found for ids" do 
      found = InheritingFromRedisBackedModel.find([0, 1])
      found.should be_instance_of(Array)
      found.count.should eq(2)
    end
    it "should have objects in the array" do
      found = InheritingFromRedisBackedModel.find([0, 1])
      found.each do |f|
        f.should be_instance_of(InheritingFromRedisBackedModel)
      end
    end
    it "should return an object if only one item is found" do
      found = InheritingFromRedisBackedModel.find(0)
      found.should be_instance_of(InheritingFromRedisBackedModel)
      found.id.should eq(0)
    end
    it "should return an object if only one item is found regardless of arguments" do
      found = InheritingFromRedisBackedModel.find(0,2,3,4,5,6,7)
      found.should be_instance_of(InheritingFromRedisBackedModel)
      found.id.should eq(0)
    end
    it "should return empty array if nothing found" do
      found = InheritingFromRedisBackedModel.find(2,3,4,5,6,7)
      found.should be_instance_of(Array)
      found.count.should eq(0)
    end
    after(:each) do
      $redis.hdel('inheriting_from_redis_backed_model:0', 'foo')
      $redis.hdel('inheriting_from_redis_backed_model:1', 'wibble')
    end
  end 
  
  describe ".exist?" do
    before(:each) do
      $redis.hset('inheriting_from_redis_backed_model:0', 'foo', 'bar')
    end
    it "should return true is the object exists" do
      InheritingFromRedisBackedModel.exists?(0).should eq true
    end
    it "should return false if the object does not exist" do
      InheritingFromRedisBackedModel.exists?(1).should eq false
    end
  end
  
end
