require "spec_helper"


describe String do 
  
  it "instance_variablizes by pre-pending an '@' and turning itself into a symbol" do 
    'my_test_string'.instance_variableize.should eq(:@my_test_string)
  end
  
  it "deinstance_variableizes by removing the leading '@" do
    '@instance_variable'.deinstance_variableize.should eq('instance_variable')
  end
  
end