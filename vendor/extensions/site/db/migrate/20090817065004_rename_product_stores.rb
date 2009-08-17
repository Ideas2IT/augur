class RenameProductStores < ActiveRecord::Migration
  def self.up
    rename_table :products_stores,:product_stores
  end

  def self.down
    rename_table :product_stores,:products_stores
  end
end