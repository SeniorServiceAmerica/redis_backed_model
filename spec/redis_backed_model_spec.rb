require "spec_helper"
require 'extras/person'

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
  
  it "has no instance variables unless specified" do 
    rbm = InheritingFromRedisBackedModel.new
    rbm.instance_variables.count.should eq(0)
  end
  
  it "creates an instance variable for a hash with one member" do
    attributes = {'id' => 1}
    rbm = InheritingFromRedisBackedModel.new(attributes)
    rbm.instance_variables.include?(:@id).should eq(true)
  end

  it "creates an instance variable for each member of an attribute hash that doesn't have scores" do
    rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
    rbm.instance_variables.count.should eq(@size)
    @attributes_with_id.each do | key, value|
      # rbm.instance_variables.include?("@#{key}".to_sym).should eq(true), "no instance variable for #{key}"
      rbm.instance_variables.include?(key.instance_variableize).should eq(true), "no instance variable for #{key}"      
    end
  end
  
  it "raises an argument error if something other than a hash is passed in" do 
    expect { InheritingFromRedisBackedModel.new('w') }.to raise_error(ArgumentError)
    expect { InheritingFromRedisBackedModel.new(['w', 1]) }.to raise_error(ArgumentError)
  end
  
  context "initializing with the attribute hash contains a score_[|] key" do 
    before(:each) do 
      @score_key = 'score_[foo|bar]'
      @attributes_with_id[@score_key]  = '[1|2]'
    end
    it "does not create a key for any score_[|] attribute" do 
      rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
      rbm.instance_variables.include?(@score_key.instance_variableize).should eq(false)
    end
  
    it "creates a scores instance variable if there are any score_[x|y] attributes" do
      rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
      rbm.instance_variables.include?('scores'.instance_variableize).should eq(true)    
    end
  end

  it "stores score_ attributes as SortedSet objects in scores" do
    ['score_[foo|bar]', 'score_[baz|qux]', 'score_[wibble|wobble]'].each_with_index do |score,index|
      @attributes_with_id[score]  = "[#{index}|#{index + 1}]"
    end
    rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
    rbm.send(:scores).each do |score|
      score.class.should eq(RedisBackedModel::SortedSet)
    end
  end

  it "does not add near matches to scores instance variable, so it tries to add it as an instance variable instead, raising a name error because of []" do
    ['score_[foobar]', 'score[foo|bar]', 'score_[foobar|]'].each_with_index do |s,i|
      @attributes_with_id[s] = '[i|i+1]'
      expect { rbm = InheritingFromRedisBackedModel.new(@attributes_with_id) }.to raise_error(NameError)
    end
  end
    
  it "returns a redis command to add the model id to a set named (model_name)_ids" do 
    rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
    rbm.send(:id_set_command).should eq("sadd|#{rbm.class.to_s.underscore}_ids|1")    
  end
  
  context "creating an hset command for an instance variable" do
    before(:each) do 
      @rbm = InheritingFromRedisBackedModel.new()
      @rbm.instance_variable_set('@id', 1)    
      @rbm.instance_variable_set('@foo', 20)      
    end
    it "creates a hset command for instance variables" do 
      @rbm.send(:instance_variable_to_redis, '@foo').should eq("hset|#{@rbm.class.to_s.underscore}:1|foo|20")
    end

    it "puts a underscored version of the model name as the first part of the hset key name in instance_variable_set" do 
      hset_command = @rbm.send(:instance_variable_to_redis, '@foo')
      hset_command.split('|')[1].split(':')[0].should eq(InheritingFromRedisBackedModel.to_s.underscore)
    end

    it "puts the id as the second part of the hset hset key name in instance_variable_set" do 
      hset_command = @rbm.send(:instance_variable_to_redis, '@foo')
      hset_command.split('|')[1].split(':')[1].should eq(@rbm.instance_variable_get('@id').to_s)  
    end
  
    it "puts the instance_variable_name (without @) as the hset field name in instance_variable_set" do
      hset_command = @rbm.send(:instance_variable_to_redis, '@foo')
      hset_command.split('|')[2].should eq('foo') 
    end
  
    it "put the instance variable value as the hset value in instance_variable_set" do 
      hset_command = @rbm.send(:instance_variable_to_redis, '@foo')
      hset_command.split('|')[3].should eq('20') 
    end
    
    it "only ever has 4 arguments" do
      @rbm.instance_variable_set('@bar', 'string with spaces')
      hset_command = @rbm.send(:instance_variable_to_redis, '@bar')
      hset_command.split('|').count.should eq(4)
    end
  end
  
  it "includes as sadd command in to_redis" do
    @attributes_with_id['score_[foo|bar]']  = '[1|2012-03-04]'
    rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
    rbm.to_redis.select { |command| command.match(/sadd/)}.count.should eq(1)
  end
  
  it "includes a hset command for each instance variable except scores in to_redis" do
    @attributes_with_id['score_[foo|bar]']  = '[1|2012-03-04]'
    rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
    expected = rbm.instance_variables.count - 1
    rbm.to_redis.select {|command| command.match(/hset/)}.count.should eq(expected)
  end
  
  it "includes a sorted_set.to_redis command for each score attribute in to_redis" do 
    scores = ['score_[foo|bar]', 'score_[baz|qux]', 'score_[wibble|wobble]']
    scores.each_with_index do |score,index|
      @attributes_with_id[score]  = "[#{index}|#{index + 1}]"
    end
    rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
    rbm.to_redis.select { |command| command.match(/zadd/) }.count.should eq(scores.count)
  end
  
  it "should not error if there are no scores" do
    rbm = InheritingFromRedisBackedModel.new(@attributes_with_id)
    rbm.to_redis.select { |command| command.include?('score')}.count.should eq(0)
  end

  it "should convert symbol attributes to strings" do
    attributes = {:id => 1, :first_name => 'jane', :last_name => 'doe'}
    rbm = InheritingFromRedisBackedModel.new(attributes)
    rbm.instance_variables.include?(:@id).should eq(true)
    rbm.instance_variable_get(:@id).should eq(1)
  end

  context "class method exist?" do
    before(:each) do
      $redis.hset 'inheriting_from_redis_backed_model:0', 'foo', 'bar'
    end
    it "should return true if hash has keys" do
      InheritingFromRedisBackedModel.exist?(0).should eq(true)
    end
  
    it "should return false if hash is empty" do
      InheritingFromRedisBackedModel.exist?(1).should eq(false)
    end
  end

end

# test inheriting from RedisBackedModel
describe Person do 
  
  before(:all) do 
    $redis.hset 'person:0', 'first_name', 'jane'
    $redis.hset 'person:0', 'last_name', 'doe'
  end

  it "should set its instance_variables from redis, using RedisBackedModel initialize" do
    person = Person.find(0)
    person.instance_variables.include?(:@first_name).should eq(true)
    person.instance_variables.include?(:@last_name).should eq(true)
    person.instance_variables.include?(:@id).should eq(true)    
  end
    
  it "should have same name method" do
    person = Person.find(0)
    person.name.should eq('jane doe')    
  end
  
end