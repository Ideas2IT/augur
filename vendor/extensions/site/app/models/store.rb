class Store < ActiveRecord::Base
  has_many :product_stores, :dependent => :destroy, :attributes => true
end
