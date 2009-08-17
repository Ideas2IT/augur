class AddIdColumnToProductStores < ActiveRecord::Migration
  def self.up
    add_column :product_stores ,:id , :primary_key ,:null =>false ,:auto_increment => true 
  end

  def self.down
    remove_column :product_stores , :id
  end
end