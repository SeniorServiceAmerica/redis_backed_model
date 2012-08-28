require "spec_helper"
# require_relative '../test/lib/person.rb'

describe RedisBackedModel do
  before(:all) do
    
  end
  
  before(:each) do
    @attributes = {}
    @size = rand(9) + 1
    key_seed = 'abcdefghijklmn'
    (1..@size).each do | i |
      key  = key_seed[i..(rand(i)+i)] 
      @attributes[key] = i
    end
    @attributes['id'] = 1
    @size += 1
  end
  
  it "has no instance variables unless specified" do 
    rbm = RedisBackedModel::RedisBackedModel.new
    rbm.instance_variables.count.should eq(0)
  end
  
  it "creates an instance variable for a hash with one member" do
    attributes = {'id' => 1}
    rbm = RedisBackedModel::RedisBackedModel.new(attributes)
    rbm.instance_variables.include?(:@id).should eq(true)
  end

  it "creates an instance variable for each member of an attribute hash that doesn't have scores" do
    rbm = RedisBackedModel::RedisBackedModel.new(@attributes)
    rbm.instance_variables.count.should eq(@size)
    @attributes.each do | key, value|
      rbm.instance_variables.include?("@#{key}".to_sym).should eq(true), "no instance variable for #{key}"
    end
  end
  
  it "raises an argument error if something other than a hash is passed in" do 
    expect { RedisBackedModel::RedisBackedModel.new('w') }.to raise_error(ArgumentError)
    expect { RedisBackedModel::RedisBackedModel.new(['w', 1]) }.to raise_error(ArgumentError)
  end
  
  it "does not create a key for any score_[|] attribute" do 
    score_key = 'score_[foo|bar]'
    @attributes[score_key]  = '[1|2]'
    rbm = RedisBackedModel::RedisBackedModel.new(@attributes)
    rbm.instance_variables.include?("@#{score_key}".to_sym).should eq(false)
  end
  
  it "creates a scores instance variable if there are any score_[x|y] attributes" do
    score_key = 'score_[foo|bar]'
    @attributes[score_key]  = '[1|2]'
    rbm = RedisBackedModel::RedisBackedModel.new(@attributes)
    rbm.instance_variables.include?("@scores".to_sym).should eq(true)    
  end

  it "stores score_ attributes in scores as SortedSet objects" do
    ['score_[foo|bar]', 'score_[baz|qux]', 'score_[wibble|wobble]'].each_with_index do |score,index|
      @attributes[score]  = "[#{index}|#{index + 1}]"
    end
    rbm = RedisBackedModel::RedisBackedModel.new(@attributes)
    rbm.send(:scores).each do |score|
      score.class.should eq(RedisBackedModel::SortedSet)
    end
  end

  it "does not add near matches to scores instance variable, so it tries to add it as an instance variable instead, raising a name error because of []" do
    ['score_[foobar]', 'score[foo|bar]', 'score_[foobar|]'].each_with_index do |s,i|
      @attributes[s] = '[i|i+1]'
      expect { rbm = RedisBackedModel::RedisBackedModel.new(@attributes) }.to raise_error(NameError)
    end
  end
    
  it "returns a redis command to adds the model id to a set named (model_name)_ids" do 
    rbm = RedisBackedModel::RedisBackedModel.new(@attributes)
    rbm.send(:redis_set_command).should eq('sadd redis_backed_model_ids 1')    
  end
  
  it "creates a hset command for instance variables that are not id" do 
    rbm = RedisBackedModel::RedisBackedModel.new()
    rbm.instance_variable_set('@id', 1)    
    rbm.instance_variable_set('@foo', 20)
    rbm.send(:instance_variable_to_redis, '@foo').should eq('hset redis_backed_model:1 foo 20')
  end

  it "puts a underscored version of the model name as the first part of the hset key name in instance_variable_set" do 
    rbm = RedisBackedModel::RedisBackedModel.new()
    rbm.instance_variable_set('@id', 1)    
    rbm.instance_variable_set('@foo', 20)
    hset_command = rbm.send(:instance_variable_to_redis, '@foo')
    hset_command.split(' ')[1].split(':')[0].should eq(RedisBackedModel.to_s.underscore)
  end

  it "puts the id as the second part of the hset hset key name in instance_variable_set" do 
    rbm = RedisBackedModel::RedisBackedModel.new()
    rbm.instance_variable_set('@id', 1)    
    rbm.instance_variable_set('@foo', 20)
    hset_command = rbm.send(:instance_variable_to_redis, '@foo')
    hset_command.split(' ')[1].split(':')[1].should eq(rbm.instance_variable_get('@id').to_s)  
  end
  
  it "puts the instance_variable_name (without @) as the hset field name in instance_variable_set" do
    rbm = RedisBackedModel::RedisBackedModel.new()
    rbm.instance_variable_set('@id', 1)    
    rbm.instance_variable_set('@foo', 20)
    hset_command = rbm.send(:instance_variable_to_redis, '@foo')
    hset_command.split(' ')[2].should eq('foo') 
  end
  
  it "put the instance variable value as the hset value in instance_variable_set" do 
    rbm = RedisBackedModel::RedisBackedModel.new()
    rbm.instance_variable_set('@id', 1)    
    rbm.instance_variable_set('@foo', 20)
    hset_command = rbm.send(:instance_variable_to_redis, '@foo')
    hset_command.split(' ')[3].should eq('20') 
  end
  
  it "does not create an hset command for the id instance variable" do
    rbm = RedisBackedModel::RedisBackedModel.new()
    rbm.instance_variable_set('@id', 1)    
    rbm.send(:instance_variable_to_redis, '@id').should eq(nil)
  end

  it "includes as sadd command in to_redis" do
    @attributes['score_[foo|bar]']  = '[1|2012-03-04]'
    rbm = RedisBackedModel::RedisBackedModel.new(@attributes)
    rbm.to_redis.select { |command| command.match(/sadd/)}.count.should eq(1)
  end
  
  it "includes a hset command for each instance variable except id in to_redis" do
    @attributes['score_[foo|bar]']  = '[1|2012-03-04]'
    rbm = RedisBackedModel::RedisBackedModel.new(@attributes)
    expected = rbm.instance_variables.count - 1
    rbm.to_redis.select {|command| command.match(/hset/)}.count.should eq(expected)
  end
  
  it "includes a sorted_set.to_redis command for each score attribute in to_redis" do 
    scores = ['score_[foo|bar]', 'score_[baz|qux]', 'score_[wibble|wobble]']
    scores.each_with_index do |score,index|
      @attributes[score]  = "[#{index}|#{index + 1}]"
    end
    rbm = RedisBackedModel::RedisBackedModel.new(@attributes)
    rbm.to_redis.select { |command| command.match(/zadd/) }.count.should eq(scores.count)
  end
end