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
    @size += 1
  end
  
  describe "on initialization" do 
  
    it "has no instance variables unless specified" do 
      rbm = InheritingFromRedisBackedModel.new
      rbm.instance_variables.count.should eq(0)
    end

    it "creates an instance variable if given a hash with one member" do
      attributes = {'id' => 1}
      rbm = InheritingFromRedisBackedModel.new(attributes)
      rbm.instance_variables.include?(:@id).should eq(true)
    end

    it "creates instance variables for each member of an attribute hash" do
      rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
      rbm.instance_variables.count.should eq(@size)
      @attributes_with_id.each do | key, value|
        rbm.instance_variables.include?(key.instance_variableize).should eq(true), "no instance variable for #{key}"      
      end
    end

    context "given an attribute hash with symbols for keys" do
      it "converts symbol attributes to strings" do
        attributes = {:id => 1, :first_name => 'jane', :last_name => 'doe'}
        rbm = InheritingFromRedisBackedModel.new(attributes)
        rbm.instance_variables.include?(:@id).should eq(true)
        rbm.instance_variable_get(:@id).should eq(1)
      end
    end


    it "raises an argument error if something other than a hash is passed in" do 
      expect { InheritingFromRedisBackedModel.new('w') }.to raise_error(ArgumentError)
      expect { InheritingFromRedisBackedModel.new(['w', 1]) }.to raise_error(ArgumentError)
    end

    context "if the attribute hash contains a score_[|] key" do 
      before(:each) do 
        scores = {'score_[foo|bar]' => '[1|2]', 'score_[qux|quux]' => '[i,ii]', 'score_[wibble|wobble]' => '[a|b]'}
        @attributes_with_id.merge!(scores)
      end
      it "creates an instance variable for each score_[baz|wubble] called sorted_set_for_baz_by_wubble" do 
        rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
        rbm.instance_variables.should include('sorted_set_for_foo_by_bar'.instance_variableize)
        rbm.instance_variables.should include('sorted_set_for_qux_by_quux'.instance_variableize)
        rbm.instance_variables.should include('sorted_set_for_wibble_by_wobble'.instance_variableize)
      end
      
      it "saves a SortedSet as the value of the score instance variable" do
        rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
        rbm.instance_variable_get('sorted_set_for_foo_by_bar'.instance_variableize).class.should eq(RedisBackedModel::SortedSet)
      end

      it "raises a name error for near matches with '[]'" do
        ['score_[foobar]', 'score[foo|bar]', 'score_[foobar|]'].each_with_index do |s,i|
          @attributes_with_id[s] = '[i|i+1]'
          expect { rbm = InheritingFromRedisBackedModel.new(@attributes_with_id) }.to raise_error(NameError)
        end
      end
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
        @hset_commands.count.should eq(2)
      end

      it "has hset commands with format 'hset|model_name:id|variable_name|variable|value'" do
         @attributes.each do |variable_name,value|
          @hset_commands.should include("hset|#{@obj.model_name_for_redis}:#{@obj.id}|#{variable_name}|#{value}") 
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
        expected = @attributes_with_id.keys.count - @scores.count
        @rbm.to_redis.select {|command| command.match(/hset/)}.count.should eq(expected)
      end

      it "creates sorted_set (zadd) commands for each score attribute" do 
        @rbm.to_redis.select { |command| command.match(/zadd/) }.count.should eq(@scores.count)
      end
    end

  end

  describe "class method 'find'" do 
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
  
  describe "class method exist?" do
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
