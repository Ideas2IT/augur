class CreateProductStores < ActiveRecord::Migration
  def self.up
    add_column :products_stores , :description_url ,:text
  end

  def self.down
    remove_column :products_stores , :description_url
  end
end
