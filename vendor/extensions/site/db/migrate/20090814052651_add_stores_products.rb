class AddStoresProducts < ActiveRecord::Migration
  def self.up
    create_table :products_stores, :id => false do |t|
      t.integer :product_id
      t.integer :store_id
    end
  end

  def self.down
    drop_table :products_stores
  end
end