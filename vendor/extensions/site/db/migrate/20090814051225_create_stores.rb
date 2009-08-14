class CreateStores < ActiveRecord::Migration
  def self.up
    create_table :stores do |t|
      t.integer :name ,:null => false
      t.string :image_url
      t.boolean :active ,:default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :stores
  end
end