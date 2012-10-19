require "spec_helper"

describe RedisBackedModel::SortedSet do
  before(:all) do
    
  end
  
  describe "matches?" do
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
  
  describe "to_redis" do

    it "returns zadd|model_name_pluralized + '_for_' + foo + '_by_' + bar + ':' + foo_id|bar_score|model_id' as to_redis" do 
      scored_set = RedisBackedModel::SortedSet.new(FalseClass, 1, {'score_[foo|bar]' => '[foo_id|bar_score]'})
      scored_set.to_redis.should eq('zadd|false_classes_for_foo_by_bar:foo_id|bar_score|1')
    end
    
    context "given a bar_score that is a date" do
      it "converts date to miliseconds" do 
        scored_set = RedisBackedModel::SortedSet.new(FalseClass, 1, {'score_[foo|date]'=>'[foo_id|2012-03-04]'})
        date_in_milliseconds = Date.civil(2012,3,4).to_time.to_f
        scored_set.to_redis.should eq("zadd|false_classes_for_foo_by_date:foo_id|#{date_in_milliseconds}|1")
      end      
    end

  end
  
end