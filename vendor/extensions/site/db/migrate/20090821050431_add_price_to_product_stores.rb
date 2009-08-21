class AddPriceToProductStores < ActiveRecord::Migration
  def self.up
    add_column :product_stores , :price ,:integer ,:default => 0
  end

  def self.down
    remove_column :product_stores , :price
  end
end