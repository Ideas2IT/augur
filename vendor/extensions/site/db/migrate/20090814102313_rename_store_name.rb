class RenameStoreName < ActiveRecord::Migration
  def self.up
    change_column :stores,:name,:string,:null=>false
    change_column :stores , :image_url , :text
  end

  def self.down
  end
end