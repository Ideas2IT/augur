require File.dirname(__FILE__) + '/../spec_helper'

describe ProductStore do
  before(:each) do
    @product_store = ProductStore.new
  end

  it "should be valid" do
    @product_store.should be_valid
  end
end
