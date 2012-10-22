require "spec_helper"
require 'ostruct'

describe RedisBackedModel::SortedSet do
  before(:all) do
    
  end
  
  describe "class method matches?" do
    it "returns true if the string matches pattern score_[foo|bar]" do
      RedisBackedModel::SortedSet.matches?('score_[foo|bar]').should eq(true)
    end
    
    it "returns false on near misses" do
      near_misses = ['score[foo|bar]', 'score_foo|bar', 'score-[foo|bar]', 'scor_[foo|bar]', 
                        'score_[foobar]', 'score_foo|bar]', 'score_[foo|bar', 'score']
      near_misses.each do |no_match|
        RedisBackedModel::SortedSet.matches?(no_match).should eq(false)
      end
    end
    
  end


  describe "instance methods" do
    before(:each) do
      @object = OpenStruct.new(:id => 1)
      @attributes = {'score_[foo|bar]' => '[foo_id|bar_score]'}
      @sorted_set = RedisBackedModel::SortedSet.new(@object, {'score_[foo|bar]' => '[foo_id|bar_score]'})
    end
  
    describe "to_instance_variable_name" do
      before(:each) do
        @name_as_string = @sorted_set.to_instance_variable_name.to_s.deinstance_variableize
      end
      it "returns a Symbol" do
        @sorted_set.to_instance_variable_name.class.should eq(Symbol)
      end
      it "starts with 'sorted_set'" do
        @name_as_string.split('_')[0..1].join('_').should eq('sorted_set')
      end
      
      it "has 'for_' + 'foo' of 'score_[foo|bar]' after sorted_set" do
        @name_as_string.split('_')[2..3].join('_').should eq('for_foo')
      end
      
      it "has 'by_' + 'bar' of 'score_[foo|bar]' after 'for_foo'" do
        @name_as_string.split('_')[4..5].join('_').should eq('by_bar')
      end
      
      it "has not other parts" do
        @name_as_string.split('_').count.should eq(6)
      end
    
    end
  
    describe "to_redis" do
      it "returns zadd|model_name_pluralized + '_for_' + foo + '_by_' + bar + ':' + foo_id|bar_score|model_id' as to_redis" do 
        @sorted_set.to_redis.should eq('zadd|open_structs_for_foo_by_bar:foo_id|bar_score|1')        
      end
    
      context "given a 'score_[x,y]' where y == 'date'" do
        it "converts date part of value to miliseconds" do 
          sorted_set = RedisBackedModel::SortedSet.new(@object, {'score_[foo|date]'=>'[foo_id|2012-03-04]'})
          date_in_milliseconds = Date.civil(2012,3,4).to_time.to_f
          sorted_set.to_redis.should eq("zadd|open_structs_for_foo_by_date:foo_id|#{date_in_milliseconds}|#{@object.id}")
        end
      end
      
      context "given definition value containing a date where y in 'score_[x|y]' != 'date' " do
        it "leave does not convert the value" do
          sorted_set = RedisBackedModel::SortedSet.new(@object, {'score_[foo|bar]'=>'[foo_id|2012-03-04]'})
          sorted_set.to_redis.should eq("zadd|open_structs_for_foo_by_bar:foo_id|2012-03-04|#{@object.id}")          
        end
      end
    end
    
    describe "add_to" do
      it "adds an instance variable to object" do
        object = double("object")
        object.should_receive(:instance_variable_set).with(@sorted_set.to_instance_variable_name, @sorted_set)
        @sorted_set.add_to(object)
      end
    end
  end
  
end