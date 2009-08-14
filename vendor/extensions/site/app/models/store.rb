class Store < ActiveRecord::Base
  has_many :products ,:through => :product_stores
end
