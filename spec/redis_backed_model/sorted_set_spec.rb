require "spec_helper"

describe RedisBackedModel::SortedSet do
  before(:all) do
    
  end
  
  before(:each) do
    @scored_set = RedisBackedModel::SortedSet.new(FalseClass, 1, {'score_[foo|bar]' => '[wibble|wobble]'})
  end

  it "returns returns first part of [|] score key as for_key" do 
    @scored_set.send(:key_for).should eq('foo')
  end
  
  it "returns first part of [|] score value as for_value" do 
    @scored_set.send(:key_value).should eq('wibble')
  end

  it "returns the model, underscored and pluralized as model_name_for_key" do 
    @scored_set.send(:key_model_name).should eq('false_classes')
  end
  
  it "returns second part of score key as score_key" do 
    @scored_set.send(:key_by).should eq('bar')
  end
  
  it "returns (key_model_name) + '_for_' + key_for + '_by_' + key_by  + ':' + key_value as sorted_set_key" do 
    @scored_set.send(:sorted_set_key).should eq('false_classes_for_foo_by_bar:wibble')
  end
  
  it "returns second part of score value as sorted_set_score" do 
    @scored_set.send(:sorted_set_score).should eq('wobble')
  end

  it "convers sorted_set_score dates to miliseconds" do 
    set = RedisBackedModel::SortedSet.new(FalseClass, 1, {'score_[foo|date]'=>'[wibble|2012-03-04]'})
    date_in_milliseconds = Date.civil(2012,3,4).to_time.to_f
    set.send(:sorted_set_score).should eq(date_in_milliseconds)
  end

  it "returns model_is as member" do
    @scored_set.send(:member).should eq(1)
    @scored_set.send(:member).should eq(@scored_set.send(:model_id))
  end

  it "returns 'zadd sorted_set_key score_value model_id' as to_redis" do 
    @scored_set.to_redis.should eq('zadd false_classes_for_foo_by_bar:wibble wobble 1')
  end
  
end